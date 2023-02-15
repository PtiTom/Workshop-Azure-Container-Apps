CREATE TABLE plaquage_ok (
	id serial PRIMARY KEY,
    sum_plaquage_ok int
);
CREATE TABLE plaquage_ko (
	id serial PRIMARY KEY,
    sum_plaquage_ko int
);

INSERT INTO plaquage_ok (id, sum_plaquage_ok)
VALUES(1, 0);

INSERT INTO plaquage_ko (id, sum_plaquage_ko)
VALUES(1, 0);