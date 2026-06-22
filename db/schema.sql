CREATE TABLE IF NOT EXISTS employees (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(120) NOT NULL,
    email       VARCHAR(160) NOT NULL UNIQUE,
    department  VARCHAR(80)  NOT NULL,
    status      VARCHAR(20)  NOT NULL DEFAULT 'active',
    role        VARCHAR(80)  NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

INSERT INTO employees (name, email, department, status, role) VALUES
    ('Ada Lovelace', 'ada@innovatech.example',  'Engineering', 'active', 'Developer'),
    ('Alan Turing',  'alan@innovatech.example', 'Security',    'active', 'Security Analyst')
ON CONFLICT (email) DO NOTHING;
