-- Jalankan seluruh isi file ini di Supabase > SQL Editor
create table if not exists services (
  id serial primary key, code text unique not null, name text not null, avg_minutes int not null default 5);
create table if not exists counters (
  id serial primary key, name text not null, active boolean not null default true);
create table if not exists tickets (
  id uuid primary key default gen_random_uuid(),
  service_id int references services(id) on delete cascade,
  number text not null, seq int not null,
  status text not null default 'waiting' check (status in ('waiting','called','done','skipped','cancelled')),
  counter_id int references counters(id),
  queue_date date not null default (now() at time zone 'Asia/Jakarta')::date,
  created_at timestamptz not null default now(), called_at timestamptz, done_at timestamptz);

alter table services enable row level security;
alter table counters enable row level security;
alter table tickets enable row level security;
create policy "read services" on services for select using (true);
create policy "read counters" on counters for select using (true);
create policy "read tickets" on tickets for select using (true);
create policy "staff update tickets" on tickets for update to authenticated using (true);
create policy "staff manage services" on services for all to authenticated using (true) with check (true);
create policy "staff manage counters" on counters for all to authenticated using (true) with check (true);

-- Ambil nomor (dipakai pengunjung tanpa login)
create or replace function take_ticket(p_service int) returns tickets
language plpgsql security definer as $$
declare s services; n int; t tickets;
begin
  select * into s from services where id = p_service;
  if not found then raise exception 'Layanan tidak ditemukan'; end if;
  perform pg_advisory_xact_lock(p_service);
  select coalesce(max(seq),0)+1 into n from tickets
    where service_id = p_service and queue_date = (now() at time zone 'Asia/Jakarta')::date;
  insert into tickets(service_id, number, seq) values (p_service, s.code || lpad(n::text,3,'0'), n)
    returning * into t;
  return t;
end $$;

-- Batalkan antrean sendiri
create or replace function cancel_ticket(p_id uuid) returns void
language sql security definer as $$
  update tickets set status='cancelled' where id=p_id and status='waiting'; $$;

-- Petugas: panggil nomor berikutnya
create or replace function call_next(p_counter int) returns tickets
language plpgsql security definer as $$
declare t tickets;
begin
  if auth.role() <> 'authenticated' then raise exception 'Harus login'; end if;
  update tickets set status='done', done_at=now() where counter_id=p_counter and status='called';
  select * into t from tickets
    where status='waiting' and queue_date=(now() at time zone 'Asia/Jakarta')::date
    order by created_at limit 1 for update skip locked;
  if not found then return null; end if;
  update tickets set status='called', counter_id=p_counter, called_at=now() where id=t.id returning * into t;
  return t;
end $$;

grant execute on function take_ticket(int), cancel_ticket(uuid) to anon, authenticated;
grant execute on function call_next(int) to authenticated;

alter publication supabase_realtime add table tickets;

insert into services(code,name,avg_minutes) values
  ('A','Customer Service',6),('B','Teller',3),('C','Informasi',2) on conflict do nothing;
insert into counters(name) values ('Loket 1'),('Loket 2'),('Loket 3');
