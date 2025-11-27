use proiect_bd;

drop table bilet;
drop table pasager;
drop table cursa;
drop table apartine_de;
drop table ruta;
drop table angajat;
drop table statie;
drop table vagon;
drop table tren;
drop table depou;

create table depou (
  id_depou int primary key,
  judet varchar(30) not null,
  oras varchar(30) not null,
  tip enum('Mentenanta', 'Adapostire') not null
);

create table tren (
  cod_uic varchar(12) primary key,
  tip_locomotiva enum('Electrica', 'Diesel') not null,
  model_locomotiva varchar(6) not null,
  id_depou int,
  constraint vf_cod_tren check (substr(cod_uic, 1, 2) in ('91', '92') and substr(cod_uic, 3, 2) = '53'),
    constraint vf_tip_locomotiva check (
    (substr(cod_uic, 1, 2) = '91' and tip_locomotiva = 'Electrica') or
    (substr(cod_uic, 1, 2) = '92' and tip_locomotiva = 'Diesel')
  ),
  constraint fk_depou_tren foreign key (id_depou) references depou(id_depou) on delete set null on update cascade
);

create table vagon (
  cod_uic varchar(12) primary key,
  cod_uic_tren varchar(12) not null,
  etajat enum('Y', 'N') not null,
  tip enum('Cuseta', 'Dormit', 'Restaurant'),
  inaltime decimal(5, 2) not null,
  constraint fk_tren_vagon foreign key (cod_uic_tren) references tren(cod_uic) on delete cascade on update cascade,
  constraint vf_etajat_vagon check (
    (substr(cod_uic, 6, 1) = '6' and etajat = 'Y') or
    (substr(cod_uic, 6, 1) != '6' and etajat = 'N')
  ),
   constraint vf_tip_vagon check (
    (substr(cod_uic, 5, 1) in ('4', '5') and tip = 'Cuseta') or
    (substr(cod_uic, 5, 1) = '7' and tip = 'Dormit') or
    (substr(cod_uic, 5, 1) = '8' and tip = 'Restaurant') or
    null
  ),
  constraint vf_inaltime_vagon check (inaltime > 0)
);

create table statie (
  id_statie varchar(5) primary key,
  nume varchar(30) not null,
  judet varchar(30) not null,
  marime enum('Gara', 'Halta') not null,
  constraint vf_marime_statie check (
    (upper(substr(id_statie, 1, 1)) = 'G' and marime = 'Gara') or
    (upper(substr(id_statie, 1, 1)) = 'H' and marime = 'Halta')
  )
);

create table angajat (
  cnp varchar(13) primary key,
  nume varchar(20),
  prenume varchar(50),
  telefon varchar(10),
  data_angajarii date not null,
  constraint vf_lungime_cnp_ang check (length(cnp) = 13),
  constraint vf_nr_cnp_ang check (substr(cnp, 1, 1) in ('1', '2', '5', '6')),
  constraint vf_tlf_ang check (telefon like '07%'),
  constraint vf_angajare_ang check (
	timestampdiff(year, 
    str_to_date(
    concat(
	case
	 when substr(cnp, 1, 1) in ('1', '2') then '19' 
	 else '20'
    end,
	substr(cnp, 2, 6)
	), '%Y%m%d'), data_angajarii) >= 18
  )
);

create table ruta (
  id_ruta int primary key,
  distanta decimal(6, 2) not null,
  durata_estimata int not null,
  pret decimal(6, 2) as ((distanta * 6) / 10) stored,
  cnp_conductor varchar(13) not null,
  cnp_controlor varchar(13) not null,
  constraint fk_conductor_ruta foreign key (cnp_conductor) references angajat(cnp) on delete cascade on update cascade,
  constraint fk_controlor_ruta foreign key (cnp_controlor) references angajat(cnp) on delete cascade on update cascade
);

create table apartine_de (
  id_ruta int not null,
  id_statie varchar(5) not null,
  nr_ordine int not null,
  constraint fk_ruta_apartine foreign key (id_ruta) references ruta(id_ruta) on delete cascade on update cascade,
  constraint fk_statie_apartine foreign key (id_statie) references statie(id_statie) on delete cascade on update cascade,
  constraint pk_apartine primary key(id_ruta, nr_ordine),
  constraint unique_apartine unique (id_ruta, id_statie)
);

create table cursa (
  id_cursa int primary key,
  id_ruta int not null,
  cod_uic varchar(12) not null,
  timp_plecare timestamp not null,
  timp_sosire timestamp not null,
  constraint fk_ruta_cursa foreign key (id_ruta) references ruta(id_ruta) on delete cascade on update cascade,
  constraint fk_tren_cursa foreign key (cod_uic) references tren(cod_uic) on delete cascade on update cascade,
  constraint vf_timp_cursa check (timp_plecare < timp_sosire)
);

create table pasager (
  cnp varchar(13) primary key,
  nume char(20),
  prenume varchar(50),
  telefon varchar(10),
  statut enum('Elev', 'Student', 'Adult', 'Pensionar') not null,
  reducere int as (
    case
      when statut = 'Elev' then 100
      when statut = 'Student' then 90
      when statut = 'Pensionar' then 50
      else 0
    end
  ) stored,
  constraint vf_lungime_cnp_pas check (length(cnp) = 13),
  constraint vf_nr_cnp_pas check (substr(cnp, 1, 1) in ('1', '2', '5', '6')),
  constraint vf_tlf_pas check (telefon like '07%')
);

alter table cursa
add constraint unique_cursa unique (id_cursa, id_ruta);

create table bilet (
  id_bilet int primary key,
  cnp varchar(13) not null,
  id_cursa int not null,
  id_ruta int not null,
  constraint fk_pasager_bilet foreign key (cnp) references pasager(cnp) on delete cascade on update cascade,
  constraint fk_ruta_cursa_bilet foreign key (id_cursa, id_ruta) references cursa(id_cursa, id_ruta) on delete cascade on update restrict
);

insert into depou (id_depou, judet, oras, tip) values (1, 'Bucuresti', 'Bucuresti', 'Mentenanta');
insert into depou (id_depou, judet, oras, tip) values (2, 'Cluj', 'Cluj-Napoca', 'Adapostire');
insert into depou (id_depou, judet, oras, tip) values (3, 'Timis', 'Timisoara', 'Mentenanta');
insert into depou (id_depou, judet, oras, tip) values (4, 'Arad', 'Arad', 'Adapostire');
insert into depou (id_depou, judet, oras, tip) values (5, 'Prahova', 'Ploiesti', 'Mentenanta');
insert into depou (id_depou, judet, oras, tip) values (6, 'Arges', 'Pitesti', 'Adapostire');
insert into depou (id_depou, judet, oras, tip) values (7, 'Sibiu', 'Sibiu', 'Mentenanta');
insert into depou (id_depou, judet, oras, tip) values (8, 'Brasov', 'Brasov', 'Adapostire');
insert into depou (id_depou, judet, oras, tip) values (9, 'Galati', 'Galati', 'Mentenanta');
insert into depou (id_depou, judet, oras, tip) values (10, 'Iasi', 'Iasi', 'Adapostire');


insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('915353040863', 'Electrica', '060EA', 2);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('915353041925', 'Electrica', '060EA', 2);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('925353062630', 'Diesel', '060DA', 2);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('925353062653', 'Diesel', '060DA', 2);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('915353046102', 'Electrica', '040EC', 3);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('915353046103', 'Electrica', '040EC', 3);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('925353089309', 'Diesel', '040DHD', 3);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('925353080437', 'Diesel', '040DHC', 3);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('925353064092', 'Diesel', 'LDEGM', 4);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('915353047755', 'Electrica', '060EA', 4);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('915353040209', 'Electrica', '060EA', 5);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('915353041210', 'Electrica', '060EA', 5);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('915353041292', 'Electrica', '060EA', 5);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('925353060103', 'Diesel', '060DA', 6);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('925353060130', 'Diesel', '060DA', 6);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('925353082014', 'Diesel', '040DHE', 6);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('925353064925', 'Diesel', 'LDEGM', 7);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('925353064927', 'Diesel', 'LDEGM', 7);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('915353040837', 'Electrica', '060EA', 8);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('915353040848', 'Electrica', '060EA', 8);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('915353040857', 'Electrica', '060EA', 9);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('925353062768', 'Diesel', '060DA', 9);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('925353080541', 'Diesel', '040DHC', 10);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('925353089223', 'Diesel', '040DHD', 10);
insert into tren (cod_uic, tip_locomotiva, model_locomotiva, id_depou) values ('915353041815', 'Electrica', '060EA', 10);


insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505346051234', '915353041925', 'Y', 'Cuseta', 3.20);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505323040863', '915353040863', 'N', null, 3.20);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505323041925', '915353041925', 'N', null, 3.50);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505353046102', '915353046102', 'N', 'Cuseta', 3.10);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505353046103', '915353046103', 'N', 'Cuseta', 3.25);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505373089309', '925353089309', 'N', 'Dormit', 3.40);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505373080437', '925353080437', 'N', 'Dormit', 3.35);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505383040209', '915353040209', 'N', 'Restaurant', 3.50);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505383041210', '915353041210', 'N', 'Restaurant', 3.60);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505383041292', '915353041292', 'N', 'Restaurant', 3.45);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505333064092', '925353064092', 'N', null, 3.15);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505343047755', '915353047755', 'N', 'Cuseta', 3.20);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505323064092', '925353064092', 'N', null, 3.30);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505323060103', '925353060103', 'N', null, 3.10);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505353060130', '925353060130', 'N', 'Cuseta', 3.25);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505373082014', '925353082014', 'N', 'Dormit', 3.30);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505373064925', '925353064925', 'N', 'Dormit', 3.40);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505388064927', '925353064927', 'N', 'Restaurant', 3.50);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505313040837', '915353040837', 'N', null, 3.60);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505313040848', '915353040848', 'N', null, 3.40);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505382040857', '915353040857', 'N', 'Restaurant', 3.45);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505377062768', '925353062768', 'N', 'Dormit', 3.35);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505355080541', '925353080541', 'N', 'Cuseta', 3.30);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505370089223', '925353089223', 'N', 'Dormit', 3.20);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505356041815', '915353041815', 'Y', 'Cuseta', 3.25);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505386041837', '925353060103', 'Y', 'Restaurant', 3.10);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505376041892', '925353060103', 'Y', 'Dormit', 3.20);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505316062768', '925353062768', 'Y', null, 3.35);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505316062785', '915353040863', 'Y', null, 3.45);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505386062790', '915353041925', 'Y', 'Restaurant', 3.50);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505356062794', '915353046102', 'Y', 'Cuseta', 3.20);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505376062798', '925353062768', 'Y', 'Dormit', 3.30);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505326062800', '925353060130', 'Y', null, 3.40);
insert into vagon (cod_uic, cod_uic_tren, etajat, tip, inaltime) values ('505346062810', '915353047755', 'Y', 'Cuseta', 3.25);


insert into statie (id_statie, nume, judet, marime) values ('G0001', 'Bucuresti Nord', 'Bucuresti','Gara');
insert into statie (id_statie, nume, judet, marime) values ('G0002', 'Ploiesti Vest', 'Prahova','Gara');
insert into statie (id_statie, nume, judet, marime) values ('H0001', 'Mizil', 'Prahova','Halta');
insert into statie (id_statie, nume, judet, marime) values ('G0003', 'Iasi', 'Iasi','Gara');
insert into statie (id_statie, nume, judet, marime) values ('G0004', 'Cluj-Napoca', 'Cluj','Gara');
insert into statie (id_statie, nume, judet, marime) values ('H0002', 'Fieni', 'Dambovita','Halta');
insert into statie (id_statie, nume, judet, marime) values ('G0005', 'Brasov', 'Brasov','Gara');
insert into statie (id_statie, nume, judet, marime) values ('H0003', 'Targoviste', 'Dambovita','Halta');
insert into statie (id_statie, nume, judet, marime) values ('G0006', 'Sibiu', 'Sibiu','Gara');
insert into statie (id_statie, nume, judet, marime) values ('H0004', 'Fagaras', 'Brasov','Halta');
insert into statie (id_statie, nume, judet, marime) values ('G0007', 'Timisoara', 'Timis','Gara');
insert into statie (id_statie, nume, judet, marime) values ('H0005', 'Caransebes', 'Caras-Severin','Halta');
insert into statie (id_statie, nume, judet, marime) values ('G0008', 'Galati', 'Galati','Gara');
insert into statie (id_statie, nume, judet, marime) values ('H0006', 'Miercurea Ciuc', 'Harghita','Halta');
insert into statie (id_statie, nume, judet, marime) values ('G0009', 'Oradea', 'Bihor','Gara');


insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('1970501050018', 'Popescu', 'Ion', '0723123456', str_to_date('2022-12-15','%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2950102034567', 'Ionescu', 'Maria', '0724123456', str_to_date('2020-03-10', '%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('1960709054321', 'Vasilescu', 'Andrei', '0725123456', str_to_date('2018-01-20', '%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2990808067890', 'Dumitrescu', 'Ana', '0726123456', str_to_date('2021-05-15', '%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('1961107043215', 'Pop', 'George', '0727123456', str_to_date('2019-09-10', '%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('1980605045432', 'Marin', 'Elena', '0728123456', str_to_date('2023-02-12', '%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2000303032109', 'Iliescu', 'Paul', '0729123456', str_to_date('2021-11-01', '%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('1950901023987', 'Rahmet', 'Cristina', '0730123456', str_to_date('2020-08-20', '%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2980406041234', 'Constantin', 'Ioana', '0731123456', str_to_date('2022-04-10', '%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('1960201056789', 'Grigore', 'Vlad', '0732123456', str_to_date('2019-07-25', '%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2950102034568', 'Popa', 'Ionela', '0723123457', str_to_date('2021-07-25', '%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2970102012345', 'Dumitrescu', 'George', '0723123458', str_to_date('2021-02-17', '%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2990102045678', 'Bucurie', 'Elena', '0723123459', str_to_date('2022-01-20', '%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2960102045432', 'Munteanu', 'Vasile', '0723123460', str_to_date('2023-03-10', '%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2940102023423', 'Stan', 'Florin', '0723123461', str_to_date('2021-08-05', '%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2910102036574', 'Lungu', 'Ion', '0723123462', str_to_date('2020-12-11', '%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2900102034421', 'Radu', 'Gabriel', '0723123463', str_to_date('2021-06-30', '%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2980102027654', 'Toma', 'Mihai', '0723123464', str_to_date('2022-11-18', '%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2930102021289', 'Vasilescu', 'Andreea', '0723123465', str_to_date('2021-09-15', '%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2990102048592', 'Popescu', 'Stefan', '0723123466', str_to_date('2023-01-05', '%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('1970101012345', 'Marcu', 'Ion', '0723000001', str_to_date('2023-02-10','%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('1950202023456', 'Ionescu', 'Alexandra', '0733000002', str_to_date('2021-07-15','%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2960605034567', 'Popa', 'Andrei', '0744000003', str_to_date('2020-05-25','%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2960506067890', 'Vasilescu', 'Elena', '0755000004', str_to_date('2019-06-30','%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('1950307067891', 'Dumitru', 'Gheorghe', '0766000005', str_to_date('2022-09-17','%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2960507080000', 'Stan', 'Ioana', '0777000006', str_to_date('2021-11-05','%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('1970409090001', 'Munteanu', 'George', '0788000007', str_to_date('2023-03-28','%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2960909091112', 'Bobaru', 'Claudia', '0799000008', str_to_date('2020-12-10','%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('1960101102345', 'Petrescu', 'Radu', '0724000009', str_to_date('2022-08-14','%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2960808075678', 'Mocanu', 'Ana', '0734000010', str_to_date('2021-06-21','%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('1970203041234', 'Ionescu', 'Vlad', '0745000011', str_to_date('2018-01-17','%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2960604065678', 'Vasilescu', 'Irina', '0756000012', str_to_date('2019-03-12','%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('1970506067899', 'Ciobanu', 'Mihai', '0767000013', str_to_date('2020-10-08','%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2960908094321', 'Popileanu', 'Elena', '0778000014', str_to_date('2021-02-13','%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('1970203056789', 'Alexandru', 'Ion', '0789000015', str_to_date('2018-12-03','%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2950605076543', 'Lucan', 'Andreea', '0790000016', str_to_date('2021-11-18','%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('1970707098765', 'Raducai', 'George', '0725000017', str_to_date('2019-09-25','%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2950808075432', 'Apreotesei', 'Cristina', '0736000018', str_to_date('2022-04-06','%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('2950606061234', 'Negru', 'Maria', '0747000019', str_to_date('2020-11-14','%Y-%m-%d'));
insert into angajat (cnp, nume, prenume, telefon, data_angajarii) values ('1960303048765', 'Chipie', 'Alina', '0758000020', str_to_date('2021-05-19','%Y-%m-%d'));


insert into ruta (id_ruta, distanta, durata_estimata, cnp_conductor, cnp_controlor) values (1, 150.5, 120, '1970501050018', '2950102034567');
insert into ruta (id_ruta, distanta, durata_estimata, cnp_conductor, cnp_controlor) values (2, 320.0, 240, '1960709054321', '2990808067890');
insert into ruta (id_ruta, distanta, durata_estimata, cnp_conductor, cnp_controlor) values (3, 180.0, 150, '1961107043215', '1980605045432');
insert into ruta (id_ruta, distanta, durata_estimata, cnp_conductor, cnp_controlor) values (4, 500.0, 420, '2000303032109', '1950901023987');
insert into ruta (id_ruta, distanta, durata_estimata, cnp_conductor, cnp_controlor) values (5, 250.0, 180, '2980406041234', '1960201056789');
insert into ruta (id_ruta, distanta, durata_estimata, cnp_conductor, cnp_controlor) values (6, 400.0, 360, '2950102034568', '2970102012345');
insert into ruta (id_ruta, distanta, durata_estimata, cnp_conductor, cnp_controlor) values (7, 650.0, 600, '2990102045678', '2960102045432');
insert into ruta (id_ruta, distanta, durata_estimata, cnp_conductor, cnp_controlor) values (8, 320.5, 260, '2940102023423', '2910102036574');
insert into ruta (id_ruta, distanta, durata_estimata, cnp_conductor, cnp_controlor) values (9, 450.0, 390, '2900102034421', '2980102027654');
insert into ruta (id_ruta, distanta, durata_estimata, cnp_conductor, cnp_controlor) values (10, 600.0, 540, '2930102021289', '2990102048592');
insert into ruta (id_ruta, distanta, durata_estimata, cnp_conductor, cnp_controlor) values (11, 150.5, 180, '1970101012345', '2950605076543');
insert into ruta (id_ruta, distanta, durata_estimata, cnp_conductor, cnp_controlor) values (12, 220, 240, '1950202023456', '2960909091112');
insert into ruta (id_ruta, distanta, durata_estimata, cnp_conductor, cnp_controlor) values (13, 180.7, 200, '2960605034567', '1970506067899');
insert into ruta (id_ruta, distanta, durata_estimata, cnp_conductor, cnp_controlor) values (14, 130, 160, '2960506067890', '1970501050018');
insert into ruta (id_ruta, distanta, durata_estimata, cnp_conductor, cnp_controlor) values (15, 160.6, 190, '1950307067891', '2960808075678');
insert into ruta (id_ruta, distanta, durata_estimata, cnp_conductor, cnp_controlor) values (16, 250, 270, '2960507080000', '2960909091112');
insert into ruta (id_ruta, distanta, durata_estimata, cnp_conductor, cnp_controlor) values (17, 140, 180, '1970409090001', '2960604065678');
insert into ruta (id_ruta, distanta, durata_estimata, cnp_conductor, cnp_controlor) values (18, 210.9, 230, '2960908094321', '1970203056789');
insert into ruta (id_ruta, distanta, durata_estimata, cnp_conductor, cnp_controlor) values (19, 200, 220, '1970203041234', '2950605076543');
insert into ruta (id_ruta, distanta, durata_estimata, cnp_conductor, cnp_controlor) values (20, 180.1, 210, '2950606061234', '1960303048765');


insert into apartine_de (id_ruta, id_statie, nr_ordine) values (1, 'G0001', 1);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (1, 'G0002', 2);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (1, 'H0001', 3);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (1, 'G0003', 4);

insert into apartine_de (id_ruta, id_statie, nr_ordine) values (2, 'G0004', 1);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (2, 'H0002', 2);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (2, 'H0003', 3);

insert into apartine_de (id_ruta, id_statie, nr_ordine) values (3, 'G0005', 1);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (3, 'H0004', 2);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (3, 'G0006', 3);

insert into apartine_de (id_ruta, id_statie, nr_ordine) values (4, 'G0007', 1);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (4, 'H0005', 2);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (4, 'G0009', 3);

insert into apartine_de (id_ruta, id_statie, nr_ordine) values (5, 'G0008', 1);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (5, 'H0006', 2);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (5, 'G0001', 3);

insert into apartine_de (id_ruta, id_statie, nr_ordine) values (6, 'G0002', 1);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (6, 'H0001', 2);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (6, 'G0004', 3);

insert into apartine_de (id_ruta, id_statie, nr_ordine) values (7, 'G0001', 1);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (7, 'G0002', 2);

insert into apartine_de (id_ruta, id_statie, nr_ordine) values (8, 'G0004', 1);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (8, 'G0006', 2);

insert into apartine_de (id_ruta, id_statie, nr_ordine) values (9, 'G0005', 1);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (9, 'H0004', 2);

insert into apartine_de (id_ruta, id_statie, nr_ordine) values (10, 'G0007', 1);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (10, 'H0005', 2);

insert into apartine_de (id_ruta, id_statie, nr_ordine) values (11, 'G0008', 1);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (11, 'H0006', 2);

insert into apartine_de (id_ruta, id_statie, nr_ordine) values (12, 'G0009', 1);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (12, 'G0004', 2);

insert into apartine_de (id_ruta, id_statie, nr_ordine) values (13, 'H0002', 1);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (13, 'H0003', 2);

insert into apartine_de (id_ruta, id_statie, nr_ordine) values (14, 'G0001', 1);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (14, 'H0001', 2);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (14, 'G0004', 3);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (14, 'G0006', 4);

insert into apartine_de (id_ruta, id_statie, nr_ordine) values (15, 'G0008', 1);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (15, 'H0002', 2);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (15, 'G0009', 3);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (15, 'G0007', 4);

insert into apartine_de (id_ruta, id_statie, nr_ordine) values (16, 'G0005', 1);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (16, 'H0001', 2);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (16, 'G0001', 3);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (16, 'G0002', 4);

insert into apartine_de (id_ruta, id_statie, nr_ordine) values (17, 'G0007', 1);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (17, 'H0005', 2);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (17, 'H0004', 3);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (17, 'G0006', 4);

insert into apartine_de (id_ruta, id_statie, nr_ordine) values (18, 'G0004', 1);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (18, 'G0008', 2);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (18, 'H0006', 3);
insert into apartine_de (id_ruta, id_statie, nr_ordine) values (18, 'G0001', 4);


insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (1, 1, '915353040863', '2024-12-29 22:00:00', '2024-12-30 00:00:00');
insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (2, 2, '915353041925', '2024-12-30 06:00:00','2024-12-30 10:00:00');
insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (3, 3, '915353040209', '2024-12-30 14:00:00','2024-12-30 16:30:00');
insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (4, 4, '915353046102', '2024-12-31 08:15:00','2024-12-31 15:15:00');
insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (5, 5, '925353062630', '2024-12-31 11:30:00','2024-12-31 14:30:00');
insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (6, 16, '925353080541','2024-12-29 20:00:00','2024-12-30 01:30:00');
insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (7, 7, '925353062653', '2024-12-30 18:00:00', '2024-12-30 23:00:00');
insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (8, 8, '925353064092', '2024-12-31 05:30:00', '2024-12-31 09:00:00');
insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (9, 9, '925353062768', '2024-12-31 09:45:00', '2024-12-31 16:00:00');
insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (10, 10, '925353064925', '2024-12-31 14:00:00','2024-12-31 23:00:00');
insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (11, 1, '915353041210', '2024-12-30 23:45:00', '2024-12-31 01:45:00');
insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (12, 2, '925353080437', '2024-12-29 19:00:00', '2024-12-29 21:30:00');
insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (13, 3, '915353046103', '2024-12-29 19:00:00', '2024-12-29 21:30:00');
insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (14, 14, '925353089309', '2024-12-30 10:00:00', '2024-12-30 15:15:00');
insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (15, 3, '915353040857', '2024-12-30 16:00:00', '2024-12-30 19:30:00');
insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (16, 16, '925353060130', '2024-12-31 21:30:00', '2025-01-01 01:30:00');
insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (17, 7, '915353041815', '2024-12-30 11:30:00', '2024-12-30 17:15:00');
insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (18, 8, '925353089223', '2024-12-30 17:00:00', '2024-12-30 20:15:00');
insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (19, 9, '915353041292', '2024-12-31 19:00:00', '2024-12-31 23:00:00');
insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (20, 18, '925353060103', '2025-01-01 05:00:00', '2025-01-01 11:00:00');
insert into cursa (id_cursa, id_ruta, cod_uic, timp_plecare, timp_sosire) values (21, 1, '915353040848', '2024-12-29 08:00:00', '2024-12-29 10:00:00');


insert into pasager (cnp, nume, prenume, telefon, statut) values ('5020202123456', 'Carut', 'Maria', '0722000002', 'Student'); 
insert into pasager (cnp, nume, prenume, telefon, statut) values ('5010101123456', 'Marcu', 'Andrei-Radu', '0722000001', 'Adult'); 
insert into pasager (cnp, nume, prenume, telefon, statut) values ('5030303123456', 'Dumitrescu', 'Alexandru', '0722000003', 'Pensionar'); 
insert into pasager (cnp, nume, prenume, telefon, statut) values ('5040404123456', 'Stanescu', 'Ioana-Ana-Maria', '0722000004', 'Elev');
insert into pasager (cnp, nume, prenume, telefon, statut) values ('5050505123456', 'Mihai', 'Cristian', '0722000005', 'Adult');
insert into pasager (cnp, nume, prenume, telefon, statut) values ('6010101123456', 'Radu', 'Elena', '0722000006', 'Student');
insert into pasager (cnp, nume, prenume, telefon, statut) values ('6020202123456', 'Tudor', 'Vlad', '0722000007', 'Pensionar');
insert into pasager (cnp, nume, prenume, telefon, statut) values ('6030303123456', 'Neagu', 'Bianca', '0722000008', 'Elev');
insert into pasager (cnp, nume, prenume, telefon, statut) values ('2970417123456', 'Dragomirisc', 'Sorin', '0722000009', 'Pensionar');
insert into pasager (cnp, nume, prenume, telefon, statut) values ('2860901123456', 'Vasile', 'Alina', '0722000010', 'Adult');
insert into pasager (cnp, nume, prenume, telefon, statut) values ('5040913123456', 'Pruna', 'Andrei', '0722000047', 'Student');


insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (1, '5020202123456', 1, 1);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (2, '5010101123456', 5, 5);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (3, '5030303123456', 3, 3);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (4, '5040404123456', 2, 2);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (5, '5040404123456', 7, 7);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (6, '5040404123456', 14, 14);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (7, '6010101123456', 6, 16);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (8, '6010101123456', 15, 3);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (9, '6030303123456', 4, 4);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (10, '6020202123456', 10, 10);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (11, '5020202123456', 10, 10);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (12, '2970417123456', 20, 18);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (13, '2970417123456', 6, 16);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (14, '6020202123456', 4, 4);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (15, '5040404123456', 7, 7);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (16, '5030303123456', 8, 8);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (17, '6020202123456', 9, 9);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (18, '5010101123456', 3, 3);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (19, '6020202123456', 6, 16);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (20, '2860901123456', 16, 16);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (21, '6010101123456', 6, 16);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (22, '5040913123456', 6, 16);
insert into bilet (id_bilet, cnp, id_cursa, id_ruta) values (23, '5040913123456', 1, 1);


drop view trenuri_depouri;
drop view ruta_statistici;
