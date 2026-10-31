-- Jalankan di SQL Editor proyek Supabase BARU.
-- GANTI 'GANTI_RAHASIA_PERANGKAT' (2 tempat di bawah: sekali di sini) dengan kata acak panjang buatanmu sendiri,
-- lalu isi kata yang SAMA di DEV_KEY pada kode ESP32.
create table public.device(id int primary key default 1, cfg jsonb not null, cfg_v int not null default 1, status jsonb not null default '{}', seen timestamptz);
create table public.dev_secret(k text not null);
create table public.cmds(id bigint generated always as identity primary key, cmd text not null, resp text, done boolean not null default false, created_at timestamptz default now());

insert into public.device(id,cfg) values(1, jsonb_build_object(
 'n',(select jsonb_agg('Saklar '||g) from generate_series(1,13) g),
 'e',(select jsonb_agg(0) from generate_series(1,13)),
 'a',(select jsonb_agg('18:00') from generate_series(1,13)),
 'b',(select jsonb_agg('22:00') from generate_series(1,13)),
 'p',(select jsonb_agg(p order by o) from unnest(array[0,1,2,3,4,5,6,7,8,9,10,20,21]) with ordinality t(p,o))));
insert into public.dev_secret values('GANTI_RAHASIA_PERANGKAT');

alter table public.device enable row level security;
alter table public.dev_secret enable row level security;
alter table public.cmds enable row level security;
create policy "d r" on public.device for select to authenticated using(true);
create policy "d w" on public.device for update to authenticated using(true) with check(true);
create policy "c r" on public.cmds for select to authenticated using(true);
create policy "c w" on public.cmds for insert to authenticated with check(true);
grant select,update on public.device to authenticated;
grant select,insert on public.cmds to authenticated;

create function public.bump() returns trigger language plpgsql as $$ begin new.cfg_v:=old.cfg_v+1; return new; end $$;
create trigger t_bump before update of cfg on public.device for each row execute function public.bump();

-- Dipanggil ESP32 tiap beberapa detik: lapor status + hasil perintah, terima perintah baru + pengaturan.
create function public.dev_sync(p_key text,p_v int,p_status jsonb,p_done jsonb) returns text
language plpgsql security definer set search_path=public as $$
declare o text:=''; d record; c record; i int; v int; g jsonb;
begin
 if p_key is distinct from (select k from dev_secret limit 1) then raise exception 'denied'; end if;
 for d in select * from jsonb_to_recordset(coalesce(p_done,'[]'::jsonb)) as x(id bigint,r text) loop
  update cmds set done=true,resp=d.r where cmds.id=d.id; end loop;
 update device set status=p_status,seen=now() where device.id=1;
 delete from cmds where done and created_at<now()-interval '1 day';
 for c in select cmds.id,cmds.cmd from cmds where not done order by cmds.id limit 5 loop
  o:=o||'K|'||c.id||'|'||replace(c.cmd,E'\n',' ')||E'\n'; end loop;
 select cfg_v,cfg into v,g from device where device.id=1;
 if v is distinct from p_v then
  o:=o||'V|'||v||E'\n';
  for i in 0..12 loop
   o:=o||'C|'||i||'|'||coalesce(g->'n'->>i,'')||'|'||coalesce(g->'e'->>i,'0')||'|'||coalesce(g->'a'->>i,'18:00')||'|'||coalesce(g->'b'->>i,'22:00')||'|'||coalesce(g->'p'->>i,'')||E'\n';
  end loop;
 end if;
 return o;
end $$;
grant execute on function public.dev_sync(text,int,jsonb,jsonb) to anon;

alter publication supabase_realtime add table public.device, public.cmds;

-- Tempat file firmware (.bin) untuk update lewat web
insert into storage.buckets(id,name,public,file_size_limit) values('fw','fw',true,3145728);
create policy "fw add" on storage.objects for insert to authenticated with check (bucket_id='fw');
create policy "fw del" on storage.objects for delete to authenticated using (bucket_id='fw');
