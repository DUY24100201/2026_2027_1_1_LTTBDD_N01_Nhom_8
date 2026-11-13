# 2026_2027_1_1_LTTBDD_N01_Nhom_8

## Tài khoản User và Admin

`UserModel` và `AdminModel` là hai loại dữ liệu riêng. `UserStorageService`
lưu User vào khóa cũ `user_accounts`, giữ nguyên ID, thông tin hồ sơ, salt và
password hash; role `ADMIN` cũ trong kho User không được xem là quyền Admin.
`AdminStorageService` lưu hồ sơ Admin riêng trong `admin_accounts`. Các storage
service dùng `StorageService` và backend Web/IO hiện có.

Đăng ký thông thường chỉ tạo User. Mật khẩu được lưu dưới dạng PBKDF2-HMAC-
SHA256 hash cùng salt. Admin production phải được xác minh bởi một
`AdminAuthenticationAuthority` tin cậy; không lưu mật khẩu Admin dạng rõ.

Để thử Admin local, hãy cấu hình mật khẩu qua build define khi chạy debug:

```sh
flutter run --dart-define=MELODY_DEV_ADMIN_PASSWORD=<development-password>
```

Tài khoản dùng để đăng nhập là `admin@melody.local`. Lần khởi tạo đầu chỉ tạo
tài khoản nếu email chưa tồn tại; các lần chạy tiếp theo không ghi đè tài khoản
hoặc mật khẩu đã lưu. Mật khẩu được lưu dưới dạng hash có salt. Tài khoản
bootstrap chỉ hoạt động trong debug, vì vậy không phát tán debug build có cấu
hình này.

Để cấp quyền Admin production, quản trị viên phải provision tài khoản qua
backend tin cậy, sau đó cấu hình implementation của
`AdminAuthenticationAuthority` trên `AuthService.instance` trước khi gọi
`initialize()`. Implementation đó phải xác minh thông tin đăng nhập và phiên
Admin ở backend, không tin role do ứng dụng gửi lên. Không cấp quyền Admin
bằng cách sửa `SharedPreferences`/`localStorage`, thêm tài khoản trong assets
hoặc nhúng mật khẩu vào source. Bản release tắt tài khoản bootstrap debug.

Các thao tác quản trị cần kiểm tra `AuthService.requireAdmin()` và access
policy tại service; chỉ ẩn giao diện là chưa đủ.

## Quản lý bài hát

Sau khi đăng nhập bằng tài khoản Admin, mở **Menu → Quản lý bài hát**. Chọn
**Tải MP3 lên** để mở form, nhập tên bài hát và ca sĩ, chọn file `.mp3`, rồi
xác nhận lưu. Form hiển thị tên và dung lượng file đã chọn. Admin có thể sửa
metadata, thay MP3/ảnh bìa và xóa bài hát. User chỉ thấy bài trong thư viện và
tìm kiếm, có thể phát, yêu thích hoặc thêm vào playlist cá nhân; thay đổi thư
viện chung bị chặn tại `SongLibraryService` nếu không phải Admin.

Metadata bài hát được lưu qua `StorageService` trong khóa `shared_songs`. Nội
dung MP3 được lưu riêng: Web dùng IndexedDB, IO dùng file bền vững trong thư
mục application support của ứng dụng. Các bài hát cũ có audio data URI được
chuyển sang lưu nhị phân khi thư viện được đọc lần đầu; dữ liệu playlist,
favorite và lịch sử nghe không bị xóa khi xóa bài hát chung. Ảnh bìa tải lên
hiện được lưu dạng data URI trong metadata.

Thư viện lưu trên thiết bị/trình duyệt hiện tại và chưa đồng bộ giữa nhiều
thiết bị. Nếu IndexedDB hoặc bộ nhớ thiết bị không đủ, thao tác lưu báo lỗi
thay vì xác nhận upload thành công.
