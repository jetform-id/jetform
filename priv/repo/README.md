Create database and user in Postgres:

```
CREATE DATABASE jeformdb;
CREATE USER jetformuser WITH ENCRYPTED PASSWORD 'Sup3rS3cret';
GRANT ALL PRIVILEGES ON DATABASE jeformdb TO jetformuser;

\c jeformdb postgres
# You are now connected to database "jeformdb" as user "postgres".

GRANT ALL ON SCHEMA public TO jetformuser;
```