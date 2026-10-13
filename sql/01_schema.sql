-- =====================================================================
-- Projeto de Banco de Dados: E-commerce (esquema refinado)
-- SGBD alvo: MySQL 8.0.16+ (necessario para CHECK constraints)
--
-- Refinamentos em relacao ao modelo base:
--   1. Cliente PJ e PF: uma conta e PF ou PJ, nunca as duas
--   2. Pagamento: um cliente pode cadastrar varias formas de pagamento
--   3. Entrega: possui status e codigo de rastreio
-- =====================================================================

DROP DATABASE IF EXISTS ecommerce;
CREATE DATABASE ecommerce CHARACTER SET utf8mb4;
USE ecommerce;

-- ---------------------------------------------------------------------
-- CLIENTE (supertipo) + CLIENTE_PF / CLIENTE_PJ (subtipos exclusivos)
--
-- A exclusividade e garantida pelo banco, sem depender da aplicacao:
--   * cliente guarda o tipo ('PF' ou 'PJ') e expoe UNIQUE (idCliente, tipo)
--   * cada subtipo repete a coluna tipo, fixa seu valor com CHECK e
--     referencia o par (idCliente, tipo) do supertipo
--   Logo, um idCliente marcado como 'PF' so consegue linha em cliente_pf,
--   e um 'PJ' so consegue linha em cliente_pj.
-- ---------------------------------------------------------------------
CREATE TABLE cliente (
    idCliente     INT AUTO_INCREMENT PRIMARY KEY,
    tipo          CHAR(2)      NOT NULL,
    email         VARCHAR(100) NOT NULL,
    telefone      VARCHAR(20),
    endereco      VARCHAR(150) NOT NULL,
    dataCadastro  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cliente_email UNIQUE (email),
    CONSTRAINT uq_cliente_id_tipo UNIQUE (idCliente, tipo),
    CONSTRAINT chk_cliente_tipo CHECK (tipo IN ('PF', 'PJ'))
);

CREATE TABLE cliente_pf (
    idCliente       INT          PRIMARY KEY,
    tipo            CHAR(2)      NOT NULL DEFAULT 'PF',
    nome            VARCHAR(60)  NOT NULL,
    sobrenome       VARCHAR(60)  NOT NULL,
    cpf             CHAR(11)     NOT NULL,
    dataNascimento  DATE,
    CONSTRAINT uq_cliente_pf_cpf UNIQUE (cpf),
    CONSTRAINT chk_cliente_pf_tipo CHECK (tipo = 'PF'),
    CONSTRAINT fk_cliente_pf_cliente FOREIGN KEY (idCliente, tipo)
        REFERENCES cliente (idCliente, tipo)
);

CREATE TABLE cliente_pj (
    idCliente      INT          PRIMARY KEY,
    tipo           CHAR(2)      NOT NULL DEFAULT 'PJ',
    razaoSocial    VARCHAR(100) NOT NULL,
    nomeFantasia   VARCHAR(100),
    cnpj           CHAR(14)     NOT NULL,
    CONSTRAINT uq_cliente_pj_cnpj UNIQUE (cnpj),
    CONSTRAINT chk_cliente_pj_tipo CHECK (tipo = 'PJ'),
    CONSTRAINT fk_cliente_pj_cliente FOREIGN KEY (idCliente, tipo)
        REFERENCES cliente (idCliente, tipo)
);

-- ---------------------------------------------------------------------
-- FORMA_PAGAMENTO: meios de pagamento cadastrados pelo cliente (1:N)
-- Nao armazenamos numero completo de cartao nem CVV; apenas dados de
-- identificacao (bandeira e final), como feito por tokenizacao.
-- ---------------------------------------------------------------------
CREATE TABLE forma_pagamento (
    idFormaPagamento  INT AUTO_INCREMENT PRIMARY KEY,
    idCliente         INT          NOT NULL,
    tipo              ENUM('CARTAO_CREDITO', 'CARTAO_DEBITO', 'BOLETO', 'PIX', 'TRANSFERENCIA') NOT NULL,
    apelido           VARCHAR(45),
    nomeTitular       VARCHAR(80),
    bandeira          VARCHAR(20),
    finalCartao       CHAR(4),
    validadeCartao    DATE,
    chavePix          VARCHAR(77),
    ativo             BOOLEAN      NOT NULL DEFAULT TRUE,
    dataCadastro      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_forma_pagamento_id_cliente UNIQUE (idFormaPagamento, idCliente),
    CONSTRAINT chk_forma_pagamento_cartao CHECK (
        tipo NOT IN ('CARTAO_CREDITO', 'CARTAO_DEBITO')
        OR (bandeira IS NOT NULL AND finalCartao IS NOT NULL AND validadeCartao IS NOT NULL)
    ),
    CONSTRAINT chk_forma_pagamento_pix CHECK (tipo <> 'PIX' OR chavePix IS NOT NULL),
    CONSTRAINT fk_forma_pagamento_cliente FOREIGN KEY (idCliente)
        REFERENCES cliente (idCliente)
);

-- ---------------------------------------------------------------------
-- PEDIDO
-- ---------------------------------------------------------------------
CREATE TABLE pedido (
    idPedido      INT AUTO_INCREMENT PRIMARY KEY,
    idCliente     INT          NOT NULL,
    status        ENUM('AGUARDANDO_PAGAMENTO', 'CONFIRMADO', 'CANCELADO') NOT NULL DEFAULT 'AGUARDANDO_PAGAMENTO',
    descricao     VARCHAR(255),
    frete         DECIMAL(10,2) NOT NULL DEFAULT 0,
    dataPedido    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_pedido_id_cliente UNIQUE (idPedido, idCliente),
    CONSTRAINT chk_pedido_frete CHECK (frete >= 0),
    CONSTRAINT fk_pedido_cliente FOREIGN KEY (idCliente)
        REFERENCES cliente (idCliente)
);

-- ---------------------------------------------------------------------
-- PAGAMENTO: associativa entre PEDIDO e FORMA_PAGAMENTO (N:M)
-- Permite pagar um pedido com mais de uma forma (ex.: dois cartoes, ou
-- cartao + pix). As duas FKs compostas incluem idCliente para garantir
-- que o pedido e a forma de pagamento pertencem ao MESMO cliente.
-- ---------------------------------------------------------------------
CREATE TABLE pagamento (
    idPagamento       INT AUTO_INCREMENT PRIMARY KEY,
    idPedido          INT          NOT NULL,
    idFormaPagamento  INT          NOT NULL,
    idCliente         INT          NOT NULL,
    valor             DECIMAL(10,2) NOT NULL,
    parcelas          TINYINT      NOT NULL DEFAULT 1,
    status            ENUM('PENDENTE', 'APROVADO', 'RECUSADO', 'ESTORNADO') NOT NULL DEFAULT 'PENDENTE',
    dataPagamento     DATETIME,
    CONSTRAINT uq_pagamento_pedido_forma UNIQUE (idPedido, idFormaPagamento),
    CONSTRAINT chk_pagamento_valor CHECK (valor > 0),
    CONSTRAINT chk_pagamento_parcelas CHECK (parcelas >= 1),
    CONSTRAINT fk_pagamento_pedido FOREIGN KEY (idPedido, idCliente)
        REFERENCES pedido (idPedido, idCliente),
    CONSTRAINT fk_pagamento_forma FOREIGN KEY (idFormaPagamento, idCliente)
        REFERENCES forma_pagamento (idFormaPagamento, idCliente)
);

-- ---------------------------------------------------------------------
-- ENTREGA: 1:1 com PEDIDO, com status e codigo de rastreio
-- O codigo de rastreio so existe depois da postagem, por isso e opcional
-- enquanto a entrega estiver em PREPARANDO e obrigatorio nos demais status.
-- ---------------------------------------------------------------------
CREATE TABLE entrega (
    idEntrega        INT AUTO_INCREMENT PRIMARY KEY,
    idPedido         INT          NOT NULL,
    status           ENUM('PREPARANDO', 'POSTADO', 'EM_TRANSITO', 'SAIU_PARA_ENTREGA', 'ENTREGUE', 'DEVOLVIDO') NOT NULL DEFAULT 'PREPARANDO',
    codigoRastreio   VARCHAR(30),
    transportadora   VARCHAR(45),
    enderecoEntrega  VARCHAR(150) NOT NULL,
    dataEnvio        DATETIME,
    previsaoEntrega  DATE,
    dataEntrega      DATETIME,
    CONSTRAINT uq_entrega_pedido UNIQUE (idPedido),
    CONSTRAINT uq_entrega_rastreio UNIQUE (codigoRastreio),
    CONSTRAINT chk_entrega_rastreio CHECK (status = 'PREPARANDO' OR codigoRastreio IS NOT NULL),
    CONSTRAINT chk_entrega_entregue CHECK (status <> 'ENTREGUE' OR dataEntrega IS NOT NULL),
    CONSTRAINT fk_entrega_pedido FOREIGN KEY (idPedido)
        REFERENCES pedido (idPedido)
);

-- ---------------------------------------------------------------------
-- PRODUTO e relacionamentos do cenario base
-- ---------------------------------------------------------------------
CREATE TABLE produto (
    idProduto    INT AUTO_INCREMENT PRIMARY KEY,
    nome         VARCHAR(100) NOT NULL,
    categoria    ENUM('ELETRONICO', 'VESTIMENTA', 'BRINQUEDO', 'ALIMENTO', 'MOVEIS') NOT NULL,
    descricao    VARCHAR(255),
    valor        DECIMAL(10,2) NOT NULL,
    CONSTRAINT chk_produto_valor CHECK (valor >= 0)
);

CREATE TABLE fornecedor (
    idFornecedor  INT AUTO_INCREMENT PRIMARY KEY,
    razaoSocial   VARCHAR(100) NOT NULL,
    cnpj          CHAR(14)     NOT NULL,
    contato       VARCHAR(20),
    CONSTRAINT uq_fornecedor_cnpj UNIQUE (cnpj)
);

CREATE TABLE vendedor_terceiro (
    idVendedor    INT AUTO_INCREMENT PRIMARY KEY,
    razaoSocial   VARCHAR(100) NOT NULL,
    nomeFantasia  VARCHAR(100),
    cnpj          CHAR(14)     NOT NULL,
    localizacao   VARCHAR(100),
    contato       VARCHAR(20),
    CONSTRAINT uq_vendedor_cnpj UNIQUE (cnpj)
);

CREATE TABLE estoque (
    idEstoque  INT AUTO_INCREMENT PRIMARY KEY,
    localizacao  VARCHAR(100) NOT NULL
);

-- Produto x Fornecedor (N:M)
CREATE TABLE produto_fornecedor (
    idProduto     INT NOT NULL,
    idFornecedor  INT NOT NULL,
    PRIMARY KEY (idProduto, idFornecedor),
    CONSTRAINT fk_prod_forn_produto FOREIGN KEY (idProduto) REFERENCES produto (idProduto),
    CONSTRAINT fk_prod_forn_fornecedor FOREIGN KEY (idFornecedor) REFERENCES fornecedor (idFornecedor)
);

-- Produto x Vendedor terceiro (N:M)
CREATE TABLE produto_vendedor (
    idVendedor  INT NOT NULL,
    idProduto   INT NOT NULL,
    quantidade  INT NOT NULL DEFAULT 1,
    PRIMARY KEY (idVendedor, idProduto),
    CONSTRAINT chk_prod_vend_qtd CHECK (quantidade >= 0),
    CONSTRAINT fk_prod_vend_vendedor FOREIGN KEY (idVendedor) REFERENCES vendedor_terceiro (idVendedor),
    CONSTRAINT fk_prod_vend_produto FOREIGN KEY (idProduto) REFERENCES produto (idProduto)
);

-- Produto x Estoque (N:M)
CREATE TABLE produto_estoque (
    idProduto   INT NOT NULL,
    idEstoque   INT NOT NULL,
    quantidade  INT NOT NULL DEFAULT 0,
    PRIMARY KEY (idProduto, idEstoque),
    CONSTRAINT chk_prod_est_qtd CHECK (quantidade >= 0),
    CONSTRAINT fk_prod_est_produto FOREIGN KEY (idProduto) REFERENCES produto (idProduto),
    CONSTRAINT fk_prod_est_estoque FOREIGN KEY (idEstoque) REFERENCES estoque (idEstoque)
);

-- Produto x Pedido (N:M): itens do pedido
CREATE TABLE item_pedido (
    idPedido       INT NOT NULL,
    idProduto      INT NOT NULL,
    quantidade     INT NOT NULL DEFAULT 1,
    precoUnitario  DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (idPedido, idProduto),
    CONSTRAINT chk_item_qtd CHECK (quantidade > 0),
    CONSTRAINT chk_item_preco CHECK (precoUnitario >= 0),
    CONSTRAINT fk_item_pedido FOREIGN KEY (idPedido) REFERENCES pedido (idPedido),
    CONSTRAINT fk_item_produto FOREIGN KEY (idProduto) REFERENCES produto (idProduto)
);
