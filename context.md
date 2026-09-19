# CONTEXT — cham-diem / Trung thu 2026

## Tổng quan
- Stack: HTML/JS thuần (không framework), Supabase REST (`zipvocbtmilyeuhqqrur.supabase.co`), deploy Vercel
- 3 trang chính + 1 trang admin: `index.html` (chấm + bình chọn + dự đoán), `khan-gia.html` (khán giả), `giam-khao.html` (BGK), `reset.html` (admin)
- Config Supabase hardcode `DC={url,key}` trong `reset.html:94`, các trang khác load từ `localStorage cd2026_config` / `setup-supabase.sql`

## Cấu trúc & Điểm nhạy cảm
- `MODELS[27]` stt 1..27 định nghĩa linh vật + `img` URL `i.ibb.co` (đã fill 27/27). **2026-09-18 đổi:** stt12 `"Và con đường mơ ước"` → `"Con đường mơ ước"`, stt5 `Ký ức quê hương` unit `Thôn Yên Thái 1` → `Thôn Yên Thái 2`; **2026-09-19 đổi:** stt22 `Vó Ngựa Phù Đổng` → `Thôn Mậu A1` (đồng bộ 3 file)
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

## Nâng cấp 2026-09-19 — Giao diện Bình chọn ảnh + Vinh danh + Xuất JSON (đã đóng gói)
1. **Card Bình chọn bằng ảnh (khán giả) — `khan-gia.html` + `index.html`**
   - `MODELS[27]` thêm `img:""` (27 linh vật) → đã fill đủ 27 URL `i.ibb.co` (WebP/JPG): `khan-gia:283-311`, `index:283-311` (vd STT1 Mậu Đông1 `Th-n-M-u-ng-1.webp`, STT22 Vó Ngựa `Th-n-M-u-A-1.webp` → `Thôn Mậu A1`)
   - CSS `vote-card-img-wrap/img/img-fallback/badge` + lightbox `#imgLightbox` (`khan-gia:194`, `index:194`) — `thumbUrl()` qua `https://images.weserv.nl/?url=...&w=480&output=webp&q=70` + `loading=lazy decoding=async`, `preconnect i.ibb.co + images.weserv.nl`, hover zoom, fallback 📷
   - `buildVoteUI()` render `imgHtml` trên đầu card + `onclick="openImgLightbox(stt)"` (lightbox full-res), nút Bình chọn `stopPropagation` — `khan-gia:785`, `index:785`
   - Đổi thôn STT22 `Vó Ngựa Phù Đổng` `Thôn Mậu A 1/Mầm non` → `Thôn Mậu A1` (đồng bộ 3 file `giam-khao:289`, `index:305`, `khan-gia:305`)

2. **Timezone VN `Asia/Ho_Chi_Minh`**
   - Thêm `parseSupabaseTime()` xử lý `2026-09-18 15:39:45.74159+00` (space/`+00`) → `T` + `:00` → `new Date` → `toLocaleString('vi-VN',{timeZone:'Asia/Ho_Chi_Minh'})`
   - `giam-khao:919-920`, `khan-gia:919`, `index:919`, `reset.html:133` — `formatVNTime()`/`toVN()`/`toVNISO()` cho cột Thời gian tab Dự đoán + JSON xuất (`created_at_vn`, `created_at_vn_iso`, `+07:00`), `exported_at_vn`

3. **Ẩn vinh danh khán giả đến khi đóng cổng — `khan-gia.html:978,1095` + `index.html:978,1095`**
   - `buildDuDoanUI()` thêm `SHOW_WINNERS = ?showWinners=1 || localStorage voting_closed=1` (mặc định `false` → ẩn)
   - Khi `!SHOW_WINNERS`: `myCardHtml` vinh danh Top3 (`Chúc mừng...`) → thay bằng `✅ Đã ghi nhận dự đoán — 🔒 Vinh danh Top 3 sẽ công bố sau khi đóng cổng`, `resultHtml` (bảng Top3) giữ `''` — `giam-khao.html` giữ nguyên (luôn hiện)

4. **Tab Dự đoán/Bình chọn — chỉ `giam-khao.html`**
   - `buildDuDoanUI:992` pagination `fetchAllDuDoan()` loop `limit 1000 offset` (tối đa 20k) cho `v_du_doan_public`/`du_doan` → `list.slice(0,100)` hiển thị 100/ tổng, footer `Hiển thị 100/${list.length}`
   - `buildVoteUI:802` thêm `Top 3 được bình chọn nhiều nhất` trước `vote-grid` — `sortedVote` theo `counts[stt]` giảm dần, render 3 card `STT, tên, đơn vị, số phiếu` (đồng bộ `khan-gia`/`index` chỉ pagination `fetchAllDuDoan` + `formatVNTime`, không ẩn Top3)

5. **`reset.html` — xuất đủ không sót + Top3 copy**
   - `fetchPaginated()` `limit 1000` + `Prefer:count=exact` parse `content-range` → total, retry 3, log từng page — `fetchAllAudience()` song song `binh_chon_khan_gia` + `du_doan` (fallback `v_du_doan_public`) → `bcTotal/duTotal` check sót + `sdt null` count
   - JSON gộp/split thêm `exported_at_vn/_iso, timezone, created_at_vn/_iso/_utc` (`reset:133,209,225`)
   - Thêm card `🏆 Copy Top 3` → `getTop3Data()` tính `actualTotal=bc.length`, `list.sort(_diff, parseSupabaseTime)` → `top3`, `formatTop3Text()` + `previewTop3()`/`copyTop3()` clipboard, log `top3Log`

## Quy tắc & Lưu ý
- Mật khẩu reset Supabase + reset thiết bị: `TT2026` (hardcode trong `reset.html`)
- Supabase anon key lộ trong `reset.html:130` — không commit key thật khi build mới, dùng placeholder
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
