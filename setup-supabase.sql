-- setup-supabase.sql — chạy 1 lần trong Supabase Dashboard > SQL Editor
-- Dự án chấm điểm Trung thu 2026 (bình chọn khán giả + dự đoán + điểm giám khảo)

-- 1. Điểm giám khảo (5 GK x 27 mô hình). Upsert theo (stt, nguoi_cham)
create table if not exists diem_trung_thu_2026 (
  stt int not null,
  ten_mo_hinh text,
  ten_don_vi text,
  nguoi_cham text not null,
  diem_c1_s1 numeric default 0, diem_c1_s2 numeric default 0, diem_c1_s3 numeric default 0,
  diem_c2_s1 numeric default 0, diem_c2_s2 numeric default 0, diem_c2_s3 numeric default 0,
  diem_c3_s1 numeric default 0, diem_c3_s2 numeric default 0, diem_c3_s3 numeric default 0,
  diem_c4_s1 numeric default 0, diem_c4_s2 numeric default 0, diem_c4_s3 numeric default 0,
  diem_c5_s1 numeric default 0, diem_c5_s2 numeric default 0,
  tong_diem numeric default 0,
  created_at timestamptz default now(),
  unique (stt, nguoi_cham)
);

-- 2. Phiếu bình chọn khán giả (1 thiết bị = 1 phiếu)
create table if not exists binh_chon_khan_gia (
  stt int not null,
  device_id text not null unique,
  voter_ip text,
  user_agent text,
  sdt varchar(11),
  ho_ten text,
  thon text,
  ten text,
  created_at timestamptz default now()
);
create index if not exists idx_binhchon_stt on binh_chon_khan_gia (stt);

-- 3. Dự đoán giải Nhất (1 thiết bị = 1 lượt)
create table if not exists du_doan (
  device_id text not null unique,
  stt_du_doan int not null,
  sdt varchar(11),
  ho_ten text,
  thon text,
  ten text,
  created_at timestamptz default now()
);
create index if not exists idx_dudoan_stt on du_doan (stt_du_doan);

-- 4. View đếm phiếu (trang bình chọn chỉ cần GET nhẹ, khỏi quét full bảng)
drop view if exists thong_ke_binh_chon cascade;
create view thong_ke_binh_chon as
  select stt, count(*)::int as so_phieu
  from binh_chon_khan_gia group by stt;

-- 5. View bảng tổng hợp điểm (5 cột GK + điểm TB)
drop view if exists bang_tong_hop_diem cascade;
create view bang_tong_hop_diem as
  select stt,
    max(ten_mo_hinh) as ten_mo_hinh,
    max(ten_don_vi) as ten_don_vi,
    max(case when nguoi_cham='loi'   then tong_diem end) as diem_gk_loi,
    max(case when nguoi_cham='hieu'  then tong_diem end) as diem_gk_hieu,
    max(case when nguoi_cham='hung'  then tong_diem end) as diem_gk_hung,
    max(case when nguoi_cham='loan'  then tong_diem end) as diem_gk_loan,
    max(case when nguoi_cham='cuong' then tong_diem end) as diem_gk_cuong,
    round(avg(tong_diem), 1) as diem_tb
  from diem_trung_thu_2026 group by stt;

-- 5b. View thống kê dự đoán (đếm số người đoán mỗi STT) — dùng DROP để tránh lỗi 42P16 cannot drop columns
drop view if exists thong_ke_du_doan cascade;
create view thong_ke_du_doan as
  select stt_du_doan as stt, stt_du_doan, count(*)::int as so_doan, count(*)::int as so_luong
  from du_doan group by stt_du_doan;

-- 5c. View public cho danh sách dự đoán (che SĐT nếu cần, vẫn cho anon đọc)
drop view if exists v_du_doan_public cascade;
create view v_du_doan_public as
  select device_id, sdt, ho_ten, thon, ten, stt_du_doan, created_at from du_doan;

-- 6. Quyền cho app (dùng anon key gọi trực tiếp, không login)
grant usage on schema public to anon;
grant select, insert on diem_trung_thu_2026, binh_chon_khan_gia, du_doan to anon;
grant select on thong_ke_binh_chon, bang_tong_hop_diem, thong_ke_du_doan, v_du_doan_public to anon;

alter table diem_trung_thu_2026 enable row level security;
alter table binh_chon_khan_gia enable row level security;
alter table du_doan enable row level security;

drop policy if exists anon_all on diem_trung_thu_2026;
drop policy if exists anon_all on binh_chon_khan_gia;
drop policy if exists anon_all on du_doan;
create policy anon_all on diem_trung_thu_2026 for all to anon using (true) with check (true);
create policy anon_all on binh_chon_khan_gia for all to anon using (true) with check (true);
create policy anon_all on du_doan for all to anon using (true) with check (true);

-- 7. Fix lỗi 42501 khi view chưa được GRANT (chạy lại nếu đã tạo DB trước đó)
grant select on thong_ke_binh_chon to anon;
grant select on bang_tong_hop_diem to anon;
grant select on thong_ke_du_doan to anon;
grant select on v_du_doan_public to anon;
-- Nếu báo 42P16 cannot drop columns -> đã fix bằng DROP VIEW IF EXISTS ở trên, chạy lại toàn file
-- Nếu báo 42501 GRANT SELECT ON public.bi... -> chạy 4 dòng GRANT trên rồi F5 lại trang khan-gia/giam-khao
