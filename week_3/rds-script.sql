create database if not exists school;

create table if not exists student (
	id 			varchar(36) not null,
	first_name 	varchar(255) not null,
	last_name 	varchar(255) not null,
	course 		int not null,
	constraint student_pk primary key (id)
);

insert into student values 
	('uuid1', 'Vasya', 'Pupkin', 1),
	('uui2', 'Petya', 'Pyatochkin', 2);

select * from student;

