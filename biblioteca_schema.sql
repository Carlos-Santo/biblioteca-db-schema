-- Criação do Banco
CREATE DATABASE BibliotecaDB;
GO

USE BibliotecaDB;
GO

-- Limpeza do ambiente
DROP TABLE IF EXISTS Emprestimo;
DROP TABLE IF EXISTS Livro;
DROP TABLE IF EXISTS Usuario;
GO

-- Tabelas

-- Criação da tabela usuário com:
-- validação impedindo campo nome de ser nulo
-- validação impedindo campo email de ser nulo e ter duplicatas
-- definição automática da data de criação do registro
CREATE TABLE Usuario (
    id_usuario INT PRIMARY KEY IDENTITY(1,1),
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    data_criacao DATETIME NOT NULL DEFAULT GETDATE())
GO



-- Criação da tabela livro com:
-- Validação para os campos titulo e autor não serem nulos
-- Validação para campo ano de publicação ser nulo e checagem para o ano ser maior que zero
-- definição automática da data de cadastro
CREATE TABLE Livro (
    id_livro INT PRIMARY KEY IDENTITY(1,1),
    titulo VARCHAR(150) NOT NULL,
    autor VARCHAR(100) NOT NULL,
    ano_publicacao INT NOT NULL
        CHECK (ano_publicacao > 0),
    data_cadastro DATETIME DEFAULT GETDATE()
);
GO



-- Criação da tabela empréstimo com:
-- Validação para os ID's de livros e usuários não serem nulos
-- Validação para data de empréstimo e data de devolução não serem nulos e data devolução não ser menor que data de emprestimo
-- Validação para Status não poder ser diferente de 'emprestado' ou devolvido 
CREATE TABLE Emprestimo (
    id_emprestimo INT PRIMARY KEY IDENTITY(1,1),
    livro_id INT NOT NULL,
    usuario_id INT NOT NULL,

    data_emprestimo DATETIME NOT NULL DEFAULT GETDATE(),
    data_devolucao DATETIME NULL,

    status VARCHAR(15) NOT NULL
        CHECK (status IN ('emprestado', 'devolvido')),

    CONSTRAINT FK_Emprestimo_Livro 
        FOREIGN KEY (livro_id) REFERENCES Livro(id_livro),

    CONSTRAINT FK_Emprestimo_Usuario 
        FOREIGN KEY (usuario_id) REFERENCES Usuario(id_usuario),

    CONSTRAINT CK_Emprestimo_Data
        CHECK (data_devolucao IS NULL OR data_devolucao >= data_emprestimo)
);
GO

-- Procedures

-- Procedure para inserção de livro
CREATE PROCEDURE sp_livro_insert
    @titulo VARCHAR(150),
    @autor VARCHAR(100),
    @ano_publicacao INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validação para titulo ser obrigatório
    IF @titulo IS NULL OR LTRIM(RTRIM(@titulo)) = ''
    BEGIN
        RAISERROR('Título é obrigatório', 16, 1);
        RETURN;
    END

    -- Validação para Autor ser obrigatório
    IF @autor IS NULL OR LTRIM(RTRIM(@autor)) = ''
    BEGIN
        RAISERROR('Autor é obrigatório', 16, 1);
        RETURN;
    END

    -- Validação para que o ano de publicação seja valido(maior que 0)
    IF @ano_publicacao <= 0
    BEGIN
        RAISERROR('Ano inválido', 16, 1);
        RETURN;
    END

    -- Caso passe pelas validações insere o cadastro do livro
    INSERT INTO Livro (titulo, autor, ano_publicacao)
    VALUES (@titulo, @autor, @ano_publicacao);
END;
GO

-- Procedure para atualização do cadastro do livro
CREATE PROCEDURE sp_livro_update
    @id_livro INT,
    @titulo VARCHAR(150),
    @autor VARCHAR(100),
    @ano_publicacao INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Valida existência do cadastro
    IF NOT EXISTS (SELECT 1 FROM Livro WHERE id_livro = @id_livro)
    BEGIN
        RAISERROR('Livro não encontrado', 16, 1);
        RETURN;
    END

    -- Validação para titulo ser obrigatório
    IF @titulo IS NULL OR LTRIM(RTRIM(@titulo)) = ''
    BEGIN
        RAISERROR('Título inválido', 16, 1);
        RETURN;
    END

    -- Validação para que o ano de publicação seja valido(maior que 0)
    IF @ano_publicacao <= 0
    BEGIN
        RAISERROR('Ano inválido', 16, 1);
        RETURN;
    END

    -- Caso passe pelas validações atualiza o cadastro do livro
    UPDATE Livro
    SET titulo = @titulo,
        autor = @autor,
        ano_publicacao = @ano_publicacao
    WHERE id_livro = @id_livro;
END;
GO

-- Procedure para exclusão do cadastro do livro
CREATE PROCEDURE sp_livro_delete
    @id_livro INT
AS
BEGIN
    SET NOCOUNT ON;

    -- valida existência do livro
    IF NOT EXISTS (SELECT 1 FROM Livro WHERE id_livro = @id_livro)
    BEGIN
        RAISERROR('Livro não encontrado', 16, 1);
        RETURN;
    END

    -- Cria uma regra de negócio para impedir a exclusão de livro com empréstimo
    IF EXISTS (SELECT 1 FROM Emprestimo WHERE livro_id = @id_livro)
    BEGIN
        RAISERROR('Não é possível excluir livro com empréstimos', 16, 1);
        RETURN;
    END

    -- Caso passe pelas validações e atenda as regras de negócio deleta o cadastro do livro
    DELETE FROM Livro WHERE id_livro = @id_livro;
END;
GO

-- Procedure para visualização do cadastro do livro
CREATE PROCEDURE sp_livro_select
    @id_livro INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Verifica se foi passado algum id, caso não retorna todos os livros, caso sim retorna apenas o livro especificado
    IF @id_livro IS NULL
    BEGIN
        SELECT * FROM Livro;
    END
    ELSE
    BEGIN
        SELECT * FROM Livro WHERE id_livro = @id_livro;
    END
END;
GO

-- Procedure para inserção de usuário
CREATE PROCEDURE sp_usuario_insert
    @nome VARCHAR(100),
    @email VARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validação para nome não ser nulo ou vazio
    IF @nome IS NULL OR LTRIM(RTRIM(@nome)) = ''
    BEGIN
        RAISERROR('Nome é obrigatório', 16, 1);
        RETURN;
    END

    -- Validação básica de formato de email
    IF @email NOT LIKE '%_@_%._%'
    BEGIN
        RAISERROR('Email inválido', 16, 1);
        RETURN;
    END

    -- Validação para impedir email duplicado
    IF EXISTS (SELECT 1 FROM Usuario WHERE email = @email)
    BEGIN
        RAISERROR('Email já cadastrado', 16, 1);
        RETURN;
    END

    -- Insere o usuário caso passe nas validações
    INSERT INTO Usuario (nome, email)
    VALUES (@nome, @email);
END;
GO

-- Procedure para consulta de usuários
CREATE PROCEDURE sp_usuario_select
    @id_usuario INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- se não for informado ID retorna todos os usuários. Se informado ID retorna apenas o usuário específico
    IF @id_usuario IS NULL
        SELECT * FROM Usuario;
    ELSE
        SELECT * FROM Usuario WHERE id_usuario = @id_usuario;
END;
GO



-- Procedure para registrar empréstimo de livro
CREATE PROCEDURE sp_emprestimo_insert
    @livro_id INT,
    @usuario_id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Valida existência do livro informado
    IF NOT EXISTS (SELECT 1 FROM Livro WHERE id_livro = @livro_id)
    BEGIN
        RAISERROR('Livro não existe', 16, 1);
        RETURN;
    END

    -- Valida existência do usuário informado
    IF NOT EXISTS (SELECT 1 FROM Usuario WHERE id_usuario = @usuario_id)
    BEGIN
        RAISERROR('Usuário não existe', 16, 1);
        RETURN;
    END

    -- Regra de negócio: impede empréstimo de livro já emprestado
    IF EXISTS (
        SELECT 1 FROM Emprestimo
        WHERE livro_id = @livro_id AND status = 'emprestado'
    )
    BEGIN
        RAISERROR('Livro já está emprestado', 16, 1);
        RETURN;
    END

    -- Insere novo empréstimo com status 'emprestado'
    INSERT INTO Emprestimo (livro_id, usuario_id, status)
    VALUES (@livro_id, @usuario_id, 'emprestado');
END;
GO

-- Procedure para atualização de empréstimo (devolução)
CREATE PROCEDURE sp_emprestimo_update
    @id_emprestimo INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Valida existência do empréstimo
    IF NOT EXISTS (SELECT 1 FROM Emprestimo WHERE id_emprestimo = @id_emprestimo)
    BEGIN
        RAISERROR('Empréstimo não encontrado', 16, 1);
        RETURN;
    END

    -- Atualiza status para 'devolvido' e define automaticamente a data de devolução
    UPDATE Emprestimo
    SET status = 'devolvido',
        data_devolucao = GETDATE()
    WHERE id_emprestimo = @id_emprestimo;
END;
GO

-- Procedure para consulta de empréstimos
CREATE PROCEDURE sp_emprestimo_select
    @id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Se não for informado ID retorna todos os empréstimos com dados de livro e usuário (JOIN). Já se informado ID retorna apenas o empréstimo específico
    IF @id IS NULL
    BEGIN
        SELECT e.*, l.titulo, u.nome
        FROM Emprestimo e
        JOIN Livro l ON e.livro_id = l.id_livro
        JOIN Usuario u ON e.usuario_id = u.id_usuario;
    END
    ELSE
    BEGIN
        SELECT * FROM Emprestimo WHERE id_emprestimo = @id;
    END
END;
GO