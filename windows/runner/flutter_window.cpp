#include "flutter_window.h"

#include <optional>
#include <thread>
#include <mutex>
#include <queue>
#include <string>
#include <vector>
#include <sstream>
#include <iostream>
#include <chrono>

#include <flutter/method_channel.h>
#include <flutter/event_channel.h>
#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"

namespace {

class PipeBridge {
 public:
  static PipeBridge& GetInstance() {
    static PipeBridge instance;
    return instance;
  }

  void Start() {
    std::thread([this]() { Run(); }).detach();
  }

  void SetEventSink(std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink) {
    std::lock_guard<std::mutex> lock(sink_mutex_);
    event_sink_ = std::move(sink);
  }

  void ClearEventSink() {
    std::lock_guard<std::mutex> lock(sink_mutex_);
    event_sink_ = nullptr;
  }

  void SendCommand(const std::string& cmd) {
    std::lock_guard<std::mutex> lock(queue_mutex_);
    write_queue_.push(cmd);
  }

 private:
  PipeBridge() : pipe_handle_(INVALID_HANDLE_VALUE) {}

  void Run() {
    const wchar_t* pipe_name = L"\\\\.\\pipe\\network_cloak_pipe";

    while (true) {
      // Attempt to connect to named pipe
      pipe_handle_ = CreateFileW(
          pipe_name,
          GENERIC_READ | GENERIC_WRITE,
          0,
          NULL,
          OPEN_EXISTING,
          0,
          NULL
      );

      if (pipe_handle_ == INVALID_HANDLE_VALUE) {
        // Sleep and retry
        std::this_thread::sleep_for(std::chrono::seconds(1));
        continue;
      }

      // Start writer thread to push commands to the service
      std::thread writer_thread([this]() { WriteLoop(); });
      
      // Keep reader running in this thread
      ReadLoop();

      // ReadLoop finished (pipe disconnected)
      if (writer_thread.joinable()) {
        writer_thread.join();
      }

      CloseHandle(pipe_handle_);
      pipe_handle_ = INVALID_HANDLE_VALUE;
      std::this_thread::sleep_for(std::chrono::seconds(1));
    }
  }

  void WriteLoop() {
    while (pipe_handle_ != INVALID_HANDLE_VALUE) {
      std::string cmd;
      {
        std::lock_guard<std::mutex> lock(queue_mutex_);
        if (!write_queue_.empty()) {
          cmd = write_queue_.front();
          write_queue_.pop();
        }
      }

      if (!cmd.empty()) {
        DWORD bytes_written = 0;
        std::string line = cmd + "\n";
        BOOL success = WriteFile(
            pipe_handle_,
            line.c_str(),
            static_cast<DWORD>(line.length()),
            &bytes_written,
            NULL
        );
        if (!success) {
          break; // Pipe error
        }
      } else {
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
      }
    }
  }

  void ReadLoop() {
    std::string buffer;
    char chunk[1024];

    while (pipe_handle_ != INVALID_HANDLE_VALUE) {
      DWORD bytes_read = 0;
      BOOL success = ReadFile(
          pipe_handle_,
          chunk,
          sizeof(chunk) - 1,
          &bytes_read,
          NULL
      );

      if (!success || bytes_read == 0) {
        break; // Disconnected or error
      }

      chunk[bytes_read] = '\0';
      buffer += chunk;

      size_t pos;
      while ((pos = buffer.find('\n')) != std::string::npos) {
        std::string line = buffer.substr(0, pos);
        buffer.erase(0, pos + 1);

        // Strip carriage return if present
        if (!line.empty() && line.back() == '\r') {
          line.pop_back();
        }

        if (!line.empty()) {
          // Parse JSON and push event to Dart
          flutter::EncodableValue val = ParseJsonToEncodable(line);
          std::lock_guard<std::mutex> lock(sink_mutex_);
          if (event_sink_) {
            event_sink_->Success(val);
          }
        }
      }
    }
  }

  // ── JSON parser & serializer helpers ─────────────────────────

  flutter::EncodableValue ParseJsonToEncodable(const std::string& line) {
    flutter::EncodableMap map;

    auto get_string = [&](const std::string& key) -> std::string {
      size_t pos = line.find("\"" + key + "\":\"");
      if (pos == std::string::npos) return "";
      size_t start = pos + key.length() + 4;
      size_t end = line.find("\"", start);
      if (end == std::string::npos) return "";
      return line.substr(start, end - start);
    };

    auto get_bool = [&](const std::string& key) -> bool {
      size_t pos = line.find("\"" + key + "\":");
      if (pos == std::string::npos) return false;
      size_t start = pos + key.length() + 3;
      return line.compare(start, 4, "true") == 0;
    };

    auto get_int = [&](const std::string& key) -> int64_t {
      size_t pos = line.find("\"" + key + "\":");
      if (pos == std::string::npos) return 0;
      size_t start = pos + key.length() + 3;
      size_t end = line.find_first_of(",}", start);
      if (end == std::string::npos) return 0;
      try {
        return std::stoll(line.substr(start, end - start));
      } catch (...) {
        return 0;
      }
    };

    std::string type = get_string("type");
    map[flutter::EncodableValue("type")] = flutter::EncodableValue(type);

    if (type == "ConnectionEvent") {
      map[flutter::EncodableValue("uid")] = flutter::EncodableValue(get_int("uid"));
      map[flutter::EncodableValue("appId")] = flutter::EncodableValue(get_string("appId"));
      map[flutter::EncodableValue("destHost")] = flutter::EncodableValue(get_string("destHost"));
      map[flutter::EncodableValue("destIp")] = flutter::EncodableValue(get_string("destIp"));
      map[flutter::EncodableValue("port")] = flutter::EncodableValue(get_int("port"));
      map[flutter::EncodableValue("protocol")] = flutter::EncodableValue(get_string("protocol"));
      map[flutter::EncodableValue("bytes")] = flutter::EncodableValue(get_int("bytes"));
      map[flutter::EncodableValue("allowed")] = flutter::EncodableValue(get_bool("allowed"));
      map[flutter::EncodableValue("timestamp")] = flutter::EncodableValue(get_int("timestamp"));
    } else if (type == "NetworkChanged") {
      map[flutter::EncodableValue("trustLevel")] = flutter::EncodableValue(get_string("trustLevel"));
      map[flutter::EncodableValue("ssid")] = flutter::EncodableValue(get_string("ssid"));
      map[flutter::EncodableValue("bssid")] = flutter::EncodableValue(get_string("bssid"));
      map[flutter::EncodableValue("authType")] = flutter::EncodableValue(get_string("authType"));
      map[flutter::EncodableValue("isRoaming")] = flutter::EncodableValue(get_bool("isRoaming"));
      map[flutter::EncodableValue("hasCaptivePortal")] = flutter::EncodableValue(get_bool("hasCaptivePortal"));
      map[flutter::EncodableValue("isCellular")] = flutter::EncodableValue(get_bool("isCellular"));
    } else if (type == "ProtectionStateChanged") {
      map[flutter::EncodableValue("isActive")] = flutter::EncodableValue(get_bool("isActive"));
    } else if (type == "AlertFired") {
      map[flutter::EncodableValue("alertType")] = flutter::EncodableValue(get_string("alertType"));
      map[flutter::EncodableValue("severity")] = flutter::EncodableValue(get_string("severity"));
      map[flutter::EncodableValue("title")] = flutter::EncodableValue(get_string("title"));
      map[flutter::EncodableValue("message")] = flutter::EncodableValue(get_string("message"));
      map[flutter::EncodableValue("appId")] = flutter::EncodableValue(get_string("appId"));
    }

    return flutter::EncodableValue(map);
  }

  HANDLE pipe_handle_;
  std::mutex queue_mutex_;
  std::queue<std::string> write_queue_;

  std::mutex sink_mutex_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;
};

// EncodableValue to JSON serializer
std::string SerializeEncodableToJson(const flutter::EncodableValue& val) {
  if (std::holds_alternative<std::string>(val)) {
    std::string s = std::get<std::string>(val);
    std::string escaped;
    for (char c : s) {
      if (c == '\\') escaped += "\\\\";
      else if (c == '"') escaped += "\\\"";
      else escaped += c;
    }
    return "\"" + escaped + "\"";
  } else if (std::holds_alternative<bool>(val)) {
    return std::get<bool>(val) ? "true" : "false";
  } else if (std::holds_alternative<int32_t>(val)) {
    return std::to_string(std::get<int32_t>(val));
  } else if (std::holds_alternative<int64_t>(val)) {
    return std::to_string(std::get<int64_t>(val));
  } else if (std::holds_alternative<double>(val)) {
    return std::to_string(std::get<double>(val));
  } else if (std::holds_alternative<flutter::EncodableList>(val)) {
    std::string json = "[";
    const auto& list = std::get<flutter::EncodableList>(val);
    for (size_t i = 0; i < list.size(); ++i) {
      if (i > 0) json += ",";
      json += SerializeEncodableToJson(list[i]);
    }
    json += "]";
    return json;
  } else if (std::holds_alternative<flutter::EncodableMap>(val)) {
    std::string json = "{";
    const auto& map = std::get<flutter::EncodableMap>(val);
    size_t i = 0;
    for (const auto& pair : map) {
      if (i > 0) json += ",";
      std::string key = std::holds_alternative<std::string>(pair.first) 
          ? std::get<std::string>(pair.first) : "";
      json += "\"" + key + "\":" + SerializeEncodableToJson(pair.second);
      i++;
    }
    json += "}";
    return json;
  }
  return "null";
}

class CustomStreamHandler : public flutter::StreamHandler<flutter::EncodableValue> {
 protected:
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnListenInternal(
      const flutter::EncodableValue* arguments,
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) override {
    PipeBridge::GetInstance().SetEventSink(std::move(events));
    return nullptr;
  }

  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnCancelInternal(
      const flutter::EncodableValue* arguments) override {
    PipeBridge::GetInstance().ClearEventSink();
    return nullptr;
  }
};

void RegisterCustomChannels(flutter::FlutterEngine* engine) {
  // Start the Named Pipe Bridge
  PipeBridge::GetInstance().Start();

  // ── Method Channel ──
  auto method_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      engine->messenger(), "com.networkcloak/commands",
      &flutter::StandardMethodCodec::GetInstance());

  method_channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        std::string method = call.method_name();

        if (method == "startFirewall" || method == "stopFirewall" || 
            method == "updateRules" || method == "activateLockdown" || 
            method == "deactivateLockdown" || method == "setDnsProfile" || 
            method == "updateBlocklists") {
          // Serialize arguments and pass to background service
          std::string payload;
          if (call.arguments()) {
            payload = "{\"method\":\"" + method + "\"," + 
                      SerializeEncodableToJson(*call.arguments()).substr(1);
          } else {
            payload = "{\"method\":\"" + method + "\"}";
          }
          PipeBridge::GetInstance().SendCommand(payload);
          result->Success();
        } else if (method == "getStatus") {
          flutter::EncodableMap map;
          map[flutter::EncodableValue("isRunning")] = flutter::EncodableValue(true);
          map[flutter::EncodableValue("isLockdown")] = flutter::EncodableValue(false);
          result->Success(flutter::EncodableValue(map));
        } else if (method == "getNetworkInfo") {
          flutter::EncodableMap map;
          map[flutter::EncodableValue("trustLevel")] = flutter::EncodableValue("trusted");
          map[flutter::EncodableValue("ssid")] = flutter::EncodableValue("Ethernet");
          map[flutter::EncodableValue("isCellular")] = flutter::EncodableValue(false);
          result->Success(flutter::EncodableValue(map));
        } else {
          result->NotImplemented();
        }
      });

  // ── Event Channel ──
  auto event_channel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      engine->messenger(), "com.networkcloak/events",
      &flutter::StandardMethodCodec::GetInstance());

  event_channel->SetStreamHandler(std::make_unique<CustomStreamHandler>());
}

} // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  RegisterCustomChannels(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  this->Show();

  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
