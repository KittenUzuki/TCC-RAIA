CREATE SCHEMA rira;


CREATE TABLE rira.Usuario (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Nome VARCHAR(100) NOT NULL,
    Email VARCHAR(150) NOT NULL UNIQUE,
    Senha VARCHAR(255) NOT NULL,
    DataCriacao DATETIME DEFAULT GETDATE()
);


CREATE TABLE rira.Ingrediente (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Nome VARCHAR(100) NOT NULL UNIQUE
);


CREATE TABLE rira.Alimento (
    Id INT PRIMARY KEY IDENTITY(1,1),
    UsuarioId INT NOT NULL,
    IngredienteId INT NOT NULL,
    Quantidade INT NOT NULL,
    DataCriacao DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (UsuarioId) REFERENCES rira.Usuario(Id),
    FOREIGN KEY (IngredienteId) REFERENCES rira.Ingrediente(Id)
);

CREATE TABLE rira.Receita (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Nome VARCHAR(150) NOT NULL,
    Descricao TEXT,
    DataCriacao DATETIME DEFAULT GETDATE()
);


CREATE TABLE rira.ReceitaIngrediente (
    Id INT PRIMARY KEY IDENTITY(1,1),
    ReceitaId INT NOT NULL,
    IngredienteId INT NOT NULL,
    Quantidade INT NOT NULL,

    FOREIGN KEY (ReceitaId) REFERENCES rira.Receita(Id),
    FOREIGN KEY (IngredienteId) REFERENCES rira.Ingrediente(Id)
);



CREATE TABLE rira.UsuarioReceitaFavorita (
    Id INT PRIMARY KEY IDENTITY(1,1),
    UsuarioId INT NOT NULL,
    ReceitaId INT NOT NULL,

    FOREIGN KEY (UsuarioId) REFERENCES rira.Usuario(Id),
    FOREIGN KEY (ReceitaId) REFERENCES rira.Receita(Id),

    UNIQUE (UsuarioId, ReceitaId)
);



/*testes*/


INSERT INTO rira.Usuario (Nome, Email, Senha)
VALUES ('Matheus', 'matheus@email.com', '123');



INSERT INTO rira.Ingrediente (Nome)
VALUES ('Tomate'), ('Ovo'), ('Leite');



INSERT INTO rira.Receita (Nome, Descricao)
VALUES ('Omelete', 'Mistura e frita');



INSERT INTO rira.ReceitaIngrediente (ReceitaId, IngredienteId, Quantidade)
VALUES (1, 2, 2), -- ovo
       (1, 3, 1); -- leite
       
       

INSERT INTO rira.Alimento (UsuarioId, IngredienteId, Quantidade)
VALUES (1, 2, 3); -- ovos
       
 



SELECT * FROM rira.Usuario;

SELECT * FROM rira.Ingrediente;

SELECT * FROM rira.Receita;

SELECT 
    r.Nome AS Receita,
    i.Nome AS Ingrediente,
    ri.Quantidade
FROM rira.ReceitaIngrediente ri
JOIN rira.Receita r ON r.Id = ri.ReceitaId
JOIN rira.Ingrediente i ON i.Id = ri.IngredienteId;


