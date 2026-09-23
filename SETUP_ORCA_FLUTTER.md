# Hướng Dẫn Setup Chạy Flutter Chrome Trên Orca (Máy Ảo Mobile) & Kết Nối Android Studio

Tài liệu này hướng dẫn chi tiết cách thiết lập và sử dụng **Orca IDE** cùng với **Flutter** và **Android Studio** trên hệ điều hành Linux (Ubuntu). 

Trong thực tế phát triển Flutter, có **2 giải pháp máy ảo** phục vụ 2 nhu cầu khác nhau:
1. **Máy Mobile ảo siêu nhẹ (Flutter Chrome / Web Mobile Emulation):** Chạy web với khung nhìn điện thoại, không ngốn RAM/CPU, mở trực tiếp bên trong hoặc cạnh Orca IDE.
2. **Máy ảo Android hoàn chỉnh (Android Studio AVD + Orca Emulator):** Dùng khi cần test các tính năng phần cứng, native API (Camera, Bluetooth, Push Notifications, SQLite, v.v.).

---

## Mục lục
- [1. Chạy Flutter Chrome trên Orca để mở máy Mobile ảo](#1-chạy-flutter-chrome-trên-orca-để-mở-máy-mobile-ảo)
  - [Cách 1: Khởi chạy Chrome với kích thước và User-Agent điện thoại](#cách-1-khởi-chạy-chrome-với-kích-thước-và-user-agent-điện-thoại)
  - [Cách 2: Nhúng cửa sổ Mobile Web trực tiếp vào Tab của Orca](#cách-2-nhúng-cửa-sổ-mobile-web-trực-tiếp-vào-tab-của-orca)
  - [Cách 3: Sử dụng Chrome DevTools Device Toolbar (Thủ công)](#cách-3-sử-dụng-chrome-devtools-device-toolbar-thủ-công)
- [2. Cấu hình biến môi trường kết nối Android Studio vào Orca](#2-cấu-hình-biến-môi-trường-kết-nối-android-studio-vào-orca)
  - [Bước 2.1: Thiết lập ANDROID_HOME và PATH](#bước-21-thiết-lập-android_home-và-path)
  - [Bước 2.2: Khắc phục cảnh báo cmdline-tools & Android Licenses](#bước-22-khắc-phục-cảnh-báo-cmdline-tools--android-licenses)
- [3. Mở và kết nối Máy ảo Android Studio với Orca](#3-mở-và-kết-nối-máy-ảo-android-studio-với-orca)
  - [Bước 3.1: Tạo và khởi động AVD từ Android Studio hoặc Terminal](#bước-31-tạo-và-khởi-động-avd-từ-android-studio-hoặc-terminal)
  - [Bước 3.2: Kiểm tra kết nối từ Orca CLI](#bước-32-kiểm-tra-kết-nối-từ-orca-cli)
  - [Bước 3.3: Chạy ứng dụng Flutter lên máy ảo từ Orca](#bước-33-chạy-ứng-dụng-flutter-lên-máy-ảo-từ-orca)
  - [Bước 3.4: Điều khiển máy ảo qua Orca Emulator](#bước-34-điều-khiển-máy-ảo-qua-orca-emulator)
- [4. Script tự động hóa tiện lợi](#4-script-tự-động-hóa-tiện-lợi)
- [5. Bảng tra cứu lệnh thường dùng](#5-bảng-tra-cứu-lệnh-thường-dùng)

---

## 1. Chạy Flutter Chrome trên Orca để mở máy Mobile ảo

Khi phát triển UI, máy ảo Android Emulator thường chiếm nhiều RAM và khởi động lâu. Chạy Flutter trên **Chrome ở chế độ Mobile Viewport** giúp bạn kiểm thử giao diện điện thoại mượt mà, hỗ trợ Hot Reload (`r`) tức thì.

### Cách 1: Khởi chạy Chrome với kích thước và User-Agent điện thoại

Flutter hỗ trợ truyền các cờ (flags) trực tiếp sang trình duyệt Chrome. Bạn có thể mở một cửa sổ Chrome độc lập có kích thước và tỷ lệ đúng chuẩn smartphone:

Chạy lệnh sau tại thư mục dự án:

```bash
flutter run -d chrome \
  --web-renderer canvaskit \
  --web-browser-flag "--window-size=412,915" \
  --web-browser-flag "--user-agent=Mozilla/5.0 (Linux; Android 14; Pixel 7)"
```

**Giải thích các cờ:**
- `-d chrome`: Chọn target là trình duyệt Google Chrome.
- `--window-size=412,915`: Cố định kích thước cửa sổ tương đương màn hình smartphone hiện đại (Pixel 7 / Galaxy S series).
- `--user-agent=...`: Giúp Flutter và các thư viện nhận diện đây là môi trường di động để bật tính năng cuộn cảm ứng (touch gestures).

---

### Cách 2: Nhúng cửa sổ Mobile Web trực tiếp vào Tab của Orca

Orca IDE tích hợp sẵn trình duyệt bên trong ứng dụng. Bạn có thể khởi động Flutter Web Server và mở nó ngay trong tab làm việc của Orca:

1. **Khởi chạy Flutter Web Server trong Terminal của Orca:**
   ```bash
   flutter run -d web-server --web-port 8080 --web-hostname localhost
   ```

2. **Mở tab preview bên trong Orca:**
   Mở một tab terminal khác trong Orca và gõ lệnh:
   ```bash
   orca tab create --url http://localhost:8080
   ```
   *(Hoặc bấm vào biểu tượng mở tab Preview/Browser có sẵn trên giao diện Orca IDE)*.

3. **Xem và tương tác:**
   Cửa sổ web sẽ hiển thị ngay cạnh trình soạn thảo code của Orca. Bạn có thể co kéo chiều rộng tab về kích thước điện thoại để vừa code vừa thấy giao diện thay đổi. Khi sửa code, bấm `r` ở terminal chạy Flutter để Hot Reload.

---

### Cách 3: Sử dụng Chrome DevTools Device Toolbar (Thủ công)

Nếu bạn chạy `flutter run -d chrome` thông thường:
1. Khi cửa sổ Chrome bật lên, nhấn `F12` (hoặc `Ctrl + Shift + I`) để mở **Chrome DevTools**.
2. Nhấn tổ hợp phím **`Ctrl + Shift + M`** để bật **Device Toolbar** (chế độ giả lập thiết bị).
3. Ở thanh công cụ trên cùng của trình duyệt:
   - **Dimensions:** Chọn thiết bị mong muốn như *iPhone 14 Pro*, *Pixel 7*, *Samsung Galaxy*, v.v.
   - Bật giả lập cảm ứng (Touch) và xoay màn hình (Rotate) theo nhu cầu.

---

## 2. Cấu hình biến môi trường kết nối Android Studio vào Orca

Để Orca IDE và các AI agent có thể tìm thấy Android Studio, Android SDK và máy ảo, bạn cần cấu hình các biến môi trường vào hệ thống.

### Bước 2.1: Thiết lập ANDROID_HOME và PATH

Mở file cấu hình shell `~/.bashrc`:

```bash
nano ~/.bashrc
```

Thêm các dòng sau vào cuối file (đường dẫn SDK mặc định trên máy của bạn là `/home/quocanh/Android/Sdk` và Android Studio ở `/opt/android-studio`):

```bash
# Android SDK & Studio configuration
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$HOME/Android/Sdk

# Thêm Android tools và Android Studio vào PATH
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:/opt/android-studio/bin
```

Lưu file (`Ctrl + O`, `Enter`, `Ctrl + X`) và áp dụng thay đổi:

```bash
source ~/.bashrc
```

Kiểm tra lại:
```bash
adb --version
emulator -version
```

---

### Bước 2.2: Khắc phục cảnh báo cmdline-tools & Android Licenses

Trước khi Flutter có thể kết nối hoàn hảo với máy ảo Android qua Orca, hãy đảm bảo các công cụ dòng lệnh đã sẵn sàng:

1. **Khởi động Android Studio:**
   ```bash
   studio.sh &
   ```
2. **Cài đặt Command-line Tools:**
   - Tại màn hình chào mừng (Welcome) hoặc thanh menu, vào **More Actions** (hoặc **Tools**) -> **SDK Manager**.
   - Chuyển sang tab **SDK Tools**.
   - Tích chọn **Android SDK Command-line Tools (latest)**.
   - Đảm bảo đã tích **Android SDK Platform-Tools** và **Android Emulator**.
   - Nhấn **Apply** -> **OK** để tải và cài đặt.

3. **Chấp nhận Android Licenses:**
   Chạy lệnh sau trong terminal và nhấn `y` cho tất cả các câu hỏi:
   ```bash
   flutter doctor --android-licenses
   ```

4. **Kiểm tra trạng thái hoàn tất:**
   ```bash
   flutter doctor
   ```
   Đảm bảo mục **Android toolchain** hiển thị dấu tích xanh `[✓]`.

---

## 3. Mở và kết nối Máy ảo Android Studio với Orca

Orca IDE tích hợp sẵn subsystem quản lý máy ảo thông qua lệnh `orca emulator`. Hệ thống này sẽ tự động nhận diện các thiết bị ảo AVD tạo từ Android Studio.

### Bước 3.1: Tạo và khởi động AVD từ Android Studio hoặc Terminal

1. **Tạo máy ảo (nếu chưa có):**
   - Trong Android Studio, mở **Device Manager** (hoặc biểu tượng điện thoại ở góc phải/Tools).
   - Chọn **Create Device** -> Chọn phần cứng (ví dụ: Pixel 7 hoặc Medium Phone).
   - Chọn phiên bản hệ điều hành Android (API 34 hoặc 35) -> Nhấn **Finish**.

2. **Khởi động máy ảo:**
   - **Cách 1:** Nhấn nút **Play** bên cạnh thiết bị trong Android Studio Device Manager.
   - **Cách 2:** Khởi động trực tiếp từ terminal Orca:
     ```bash
     # Liệt kê các máy ảo có sẵn
     emulator -list-avds
     
     # Chạy máy ảo (ví dụ: Medium_Phone)
     emulator @Medium_Phone &
     ```

---

### Bước 3.2: Kiểm tra kết nối từ Orca CLI

Khi máy ảo Android đã khởi động xong, hãy kiểm tra khả năng nhận diện của Orca:

```bash
orca emulator devices
```

Kết quả sẽ hiển thị thiết bị đang hoạt động (ví dụ):
```text
Android  booted  emulator-5554  (Medium_Phone)
```

Bạn cũng có thể xem dạng JSON chi tiết:
```bash
orca emulator devices --json
```

---

### Bước 3.3: Chạy ứng dụng Flutter lên máy ảo từ Orca

1. Kiểm tra Flutter đã nhận máy ảo chưa:
   ```bash
   flutter devices
   ```
   Thiết bị sẽ xuất hiện dưới dạng `emulator-5554` hoặc tên AVD.

2. Chạy ứng dụng Flutter trực tiếp từ Orca:
   ```bash
   flutter run -d emulator-5554
   ```
   Ứng dụng sẽ được build và tự động cài đặt lên máy ảo Android. Các thao tác Hot Reload (`r`) và Hot Restart (`R`) đều hoạt động bình thường trong terminal Orca.

---

### Bước 3.4: Điều khiển máy ảo qua Orca Emulator

Orca hỗ trợ điều khiển máy ảo Android thông qua `adb shell input` mà không cần rời khỏi bàn phím:

| Thao tác | Lệnh Orca CLI | Ghi chú |
| :--- | :--- | :--- |
| **Xem danh sách máy ảo** | `orca emulator devices` | Xem máy ảo nào đang chạy |
| **Chạm vào màn hình (Tap)** | `orca emulator tap 0.5 0.5 --device emulator-5554` | Tọa độ chuẩn hóa từ `0.0` đến `1.0` (0.5 0.5 là chính giữa) |
| **Gõ chữ** | `orca emulator type "Test text" --device emulator-5554` | Nhập văn bản vào ô input đang focus |
| **Nút Back** | `orca emulator button back --device emulator-5554` | Quay lại màn hình trước |
| **Nút Home** | `orca emulator button home --device emulator-5554` | Về màn hình chính |
| **Nút Recents** | `orca emulator button recents --device emulator-5554` | Mở danh sách đa nhiệm |
| **Xoay màn hình** | `orca emulator rotate landscape_left --device emulator-5554` | Xoay ngang thiết bị |
| **Xem Logcat** | `orca emulator logcat --lines 100 --device emulator-5554` | Đọc log gần nhất của Android |
| **Cài APK** | `orca emulator install ./app-debug.apk --reinstall --device emulator-5554` | Cài đặt lại gói APK |

---

## 4. Script tự động hóa tiện lợi

Để tiết kiệm thời gian, bạn có thể tạo một script chạy nhanh trong thư mục dự án.

Tạo file `run_mobile.sh`:
```bash
nano run_mobile.sh
```

Dán nội dung sau:

```bash
#!/bin/bash
# Script khởi chạy Flutter Mobile Web giả lập hoặc Android Emulator

echo "=============================================="
echo " Chọn chế độ chạy Flutter trên Orca: "
echo " 1) Flutter Chrome Mobile (Siêu nhẹ, mở ngay) "
echo " 2) Flutter Web Server (Mở trong Orca Tab)   "
echo " 3) Khởi động Android Emulator & Chạy App     "
echo "=============================================="
read -p "Nhập lựa chọn (1/2/3): " choice

case $choice in
  1)
    echo "Đang mở Flutter Chrome Mobile Viewport..."
    flutter run -d chrome \
      --web-renderer canvaskit \
      --web-browser-flag "--window-size=412,915" \
      --web-browser-flag "--user-agent=Mozilla/5.0 (Linux; Android 14; Pixel 7)"
    ;;
  2)
    echo "Đang mở Flutter Web Server tại cổng 8080..."
    echo "Trong Orca, chạy lệnh: orca tab create --url http://localhost:8080"
    flutter run -d web-server --web-port 8080 --web-hostname localhost
    ;;
  3)
    echo "Kiểm tra danh sách máy ảo Android..."
    avd_name=$(emulator -list-avds | head -n 1)
    if [ -z "$avd_name" ]; then
      echo "Lỗi: Không tìm thấy AVD nào! Hãy mở Android Studio để tạo máy ảo."
      exit 1
    fi
    echo "Đang khởi động AVD: $avd_name..."
    emulator @"$avd_name" &
    echo "Đang chờ thiết bị sẵn sàng..."
    adb wait-for-device
    sleep 3
    echo "Chạy Flutter app lên thiết bị..."
    flutter run
    ;;
  *)
    echo "Lựa chọn không hợp lệ."
    ;;
esac
```

Cấp quyền thực thi:
```bash
chmod +x run_mobile.sh
```

Mỗi lần cần test, bạn chỉ cần gõ `./run_mobile.sh`.

---

## 5. Bảng tra cứu lệnh thường dùng

```bash
# Kiểm tra tổng thể môi trường Flutter & Android
flutter doctor -v

# Xem danh sách thiết bị Flutter nhận diện
flutter devices

# Xem danh sách thiết bị và máy ảo Orca nhận diện
orca emulator devices

# Chạy Flutter trên Chrome chế độ Mobile
flutter run -d chrome --web-browser-flag "--window-size=412,915"

# Chạy Flutter trên Android Emulator đầu tiên
flutter run -d android

# Mở Android Studio
studio.sh &

# Mở máy ảo AVD bằng dòng lệnh
emulator @Medium_Phone &
```
