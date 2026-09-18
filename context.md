# CONTEXT — cham-diem / Trung thu 2026

## Tổng quan
- Stack: HTML/JS thuần (không framework), Supabase REST (`zipvocbtmilyeuhqqrur.supabase.co`), deploy Vercel
- 3 trang chính + 1 trang admin: `index.html` (chấm + bình chọn + dự đoán), `khan-gia.html` (khán giả), `giam-khao.html` (BGK), `reset.html` (admin)
- Config Supabase hardcode `DC={url,key}` trong `reset.html:94`, các trang khác load từ `localStorage cd2026_config` / `setup-supabase.sql`

## Cấu trúc & Điểm nhạy cảm
- `MODELS[24]` stt 1..24 định nghĩa linh vật. **2026-09-18 đổi:** stt12 `"Và con đường mơ ước"` → `"Con đường mơ ước"`, stt5 `Ký ức quê hương` unit `Thôn Yên Thái 1` → `Thôn Yên Thái 2` (áp dụng cả 3 file: `index:262/269`, `khan-gia:262/269`, `giam-khao:263/270`)
- `CRITERIA[5]` tiêu chí chấm, `JUDGES` + `SK(j)` key localStorage `cd2026_gk_<judge>`
- LocalStorage keys: `bc_device_id` / `cd2026_device_id` (device UUID), `kg_info` (JSON họ tên/thôn/sdt), `da_binh_chon`, `da_du_doan`, `saved_sdt`/`SDT_STORAGE_KEY`, `cd2026_config`, `desktop_popup_dismissed`, `cd2026_*` / `*binh_chon*` / `*du_doan*`
- SessionStorage: `desktop_popup_dismissed`
- Supabase tables: `du_doan` (device_id, sdt, ho_ten/thon, stt_du_doan), `binh_chon_khan_gia` (device_id, sdt, stt), `diem_trung_thu_2026` (nguoi_cham, stt, diem_c*_s*, tong_diem)
- Popup desktop: `.desktop-popup-overlay` (khuyên dùng điện thoại, cho phép `Tiếp tục xem`, lưu `sessionStorage desktop_popup_dismissed`)
- `buildModels()` tạo thẻ `.model-card` + `.model-body` (mặc định `display:none`, `.open` mới hiện). `toggleModel(idx)` toggle.

## Nâng cấp 2026-09-18 (đã làm)
1. **reset.html — xóa toàn bộ localStorage thiết bị**
   - `confirmResetDevice():98-110` đổi từ `removeItem` lẻ → `localStorage.clear()+sessionStorage.clear()`
   - Thêm nút `🧹 Xóa sạch localStorage máy này` → `clearAllStorage():132`
   - `doResetSelected(true):181` khi tick khớp máy này → `clear()` toàn bộ
   - Thêm `clearLocalForSelected():142` — tick trong danh sách, nếu khớp `bc_device_id`/`cd2026_device_id` thì clear máy này (có confirm phân biệt)
   - `loadDevices():166` highlight `📍 Máy này` (nền `#fffbeb`, viền `#fbbf24`) khi `device_id === myId`

2. **Link tự xóa cho khán giả (remote reset)**
   - `reset.html` thêm card `🔗 Link tự xóa` + `setShareLink()/copyShareLink()/initShareLink` tạo `.../khan-gia.html?clear=1` / `index.html?clear=1` / `/?clear=1`
   - `index.html:254`, `khan-gia.html:254`, `giam-khao.html:255` đầu `<script>` thêm auto-clear: `if(p.has('clear'||'reset'||'xoa')){localStorage.clear();sessionStorage.clear(); history.replaceState...; alert(...)}` → gửi link là họ tự xóa, không cần vào máy họ

3. **Thẻ chấm điểm tự mở**
   - `giam-khao:586`, `index:553`, `khan-gia:552` `buildModels()` thêm `${idx===0?'open':''}` + `setTimeout add open body_0` → thẻ đầu tự bung

4. **Chống F12 khi cố tình dùng máy tính**
   - `index:255`, `khan-gia:255`, `giam-khao:255` thêm: chặn `contextmenu`, chặn `F12`/`Ctrl+Shift+I/J/C`/`Ctrl+U/S`, `setInterval` phát hiện DevTools (outer-inner>160) → `console.clear()`

## Quy tắc & Lưu ý
- Mật khẩu reset Supabase + reset thiết bị: `TT2026` (hardcode trong `reset.html`)
- Supabase anon key lộ trong `reset.html:94` — không commit key thật khi build mới, dùng placeholder
- Token saver: AGENTS.md yêu cầu không đọc bừa bãi, chỉ đọc file được chỉ định, báo cáo ngắn <10 dòng
- Không tạo file/dependency mới nếu không cần; không tự git commit/push

## Fix 2026-09-18 — lỗi 23514 du_doan_stt_du_doan_check
- Nguyên nhân: bảng `du_doan` cũ có `CHECK (stt_du_doan BETWEEN 1 AND 27)` (dự đoán STT linh vật), logic mới dự đoán **tổng số người bình chọn** (0-10000) nên `stt_du_doan=50/100/500` vi phạm
- Code gửi `payload {stt_du_doan:v, tong_du_doan:v}` (index/khan-gia/giam-khao:1080,1085/1117,1122) nên vẫn dính constraint cũ
- Fix DB: `alter table du_doan drop constraint if exists du_doan_stt_du_doan_check` (+ 2 tên biến thể) đã thêm vào `setup-supabase.sql:50-52`
- Chạy ngay trong Supabase > SQL Editor: copy 3 dòng DROP ở trên

## Việc tiếp theo gợi ý
- Thay hardcode `DC` bằng `cd2026_config` + env
- Thêm RLS DELETE cho anon nếu reset Supabase báo 403
- Cân nhắc mở tất cả thẻ (`open` cho mọi `model-body`) nếu BGK muốn chấm liền mạch, hoặc thêm nút "Mở tất cả / Đóng tất cả"
- Đồng bộ `MODELS` ra `js/config.js` chung để tránh sửa 3 file
- Thêm rate-limit / check SĐT trùng Supabase thay vì chỉ localStorage
