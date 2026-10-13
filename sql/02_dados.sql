-- Dados ficticios para testar o esquema (CPFs e CNPJs nao correspondem a pessoas reais)
USE ecommerce;

-- Clientes: o supertipo recebe o tipo, o subtipo recebe os dados especificos
INSERT INTO cliente (idCliente, tipo, email, telefone, endereco) VALUES
    (1, 'PF', 'maria.silva@email.com',  '11911110001', 'Rua das Flores, 100 - Sao Paulo/SP'),
    (2, 'PF', 'joao.souza@email.com',   '21911110002', 'Av. Atlantica, 200 - Rio de Janeiro/RJ'),
    (3, 'PJ', 'compras@techsolucoes.com', '1133330003', 'Rua da Industria, 300 - Campinas/SP');

INSERT INTO cliente_pf (idCliente, nome, sobrenome, cpf, dataNascimento) VALUES
    (1, 'Maria', 'Silva', '11111111111', '1990-04-12'),
    (2, 'Joao',  'Souza', '22222222222', '1985-09-30');

INSERT INTO cliente_pj (idCliente, razaoSocial, nomeFantasia, cnpj) VALUES
    (3, 'Tech Solucoes Ltda', 'TechSol', '11222333000144');

-- Formas de pagamento: a Maria tem tres cadastradas
INSERT INTO forma_pagamento (idFormaPagamento, idCliente, tipo, apelido, nomeTitular, bandeira, finalCartao, validadeCartao, chavePix) VALUES
    (1, 1, 'CARTAO_CREDITO', 'Cartao principal', 'MARIA SILVA', 'VISA',       '1234', '2030-12-01', NULL),
    (2, 1, 'CARTAO_CREDITO', 'Cartao reserva',   'MARIA SILVA', 'MASTERCARD', '5678', '2029-06-01', NULL),
    (3, 1, 'PIX',            'Pix e-mail',       NULL,          NULL,         NULL,   NULL,         'maria.silva@email.com'),
    (4, 2, 'BOLETO',         NULL,               NULL,          NULL,         NULL,   NULL,         NULL),
    (5, 3, 'TRANSFERENCIA',  'Conta empresa',    NULL,          NULL,         NULL,   NULL,         NULL);

INSERT INTO produto (idProduto, nome, categoria, descricao, valor) VALUES
    (1, 'Fone Bluetooth',  'ELETRONICO', 'Fone sem fio com cancelamento de ruido', 250.00),
    (2, 'Camiseta Basica', 'VESTIMENTA', 'Camiseta de algodao',                     49.90),
    (3, 'Notebook 14"',    'ELETRONICO', 'Notebook 16GB RAM, 512GB SSD',            4200.00);

INSERT INTO fornecedor (idFornecedor, razaoSocial, cnpj, contato) VALUES
    (1, 'Distribuidora Alfa Ltda', '12345678000190', '1144440001');

INSERT INTO vendedor_terceiro (idVendedor, razaoSocial, nomeFantasia, cnpj, localizacao, contato) VALUES
    (1, 'Moda Express ME', 'Moda Express', '98765432000110', 'Belo Horizonte/MG', '3155550001');

INSERT INTO estoque (idEstoque, localizacao) VALUES
    (1, 'Sao Paulo/SP'),
    (2, 'Recife/PE');

INSERT INTO produto_fornecedor (idProduto, idFornecedor) VALUES (1, 1), (3, 1);
INSERT INTO produto_vendedor (idVendedor, idProduto, quantidade) VALUES (1, 2, 120);
INSERT INTO produto_estoque (idProduto, idEstoque, quantidade) VALUES (1, 1, 50), (2, 2, 300), (3, 1, 15);

-- Pedido 1: Maria compra fone + camiseta e paga com DOIS meios (cartao + pix)
INSERT INTO pedido (idPedido, idCliente, status, descricao, frete) VALUES
    (1, 1, 'CONFIRMADO', 'Compra de fone e camiseta', 20.00),
    (2, 2, 'AGUARDANDO_PAGAMENTO', 'Compra de camiseta', 15.00),
    (3, 3, 'CONFIRMADO', 'Notebook corporativo', 0.00);

INSERT INTO item_pedido (idPedido, idProduto, quantidade, precoUnitario) VALUES
    (1, 1, 1, 250.00),
    (1, 2, 2, 49.90),
    (2, 2, 1, 49.90),
    (3, 3, 1, 4200.00);

INSERT INTO pagamento (idPedido, idFormaPagamento, idCliente, valor, parcelas, status, dataPagamento) VALUES
    (1, 1, 1, 200.00, 2, 'APROVADO', NOW()),
    (1, 3, 1, 169.80, 1, 'APROVADO', NOW()),
    (2, 4, 2, 64.90,  1, 'PENDENTE', NULL),
    (3, 5, 3, 4200.00, 1, 'APROVADO', NOW());

-- Entregas: cada pedido tem status e, apos a postagem, codigo de rastreio
INSERT INTO entrega (idPedido, status, codigoRastreio, transportadora, enderecoEntrega, dataEnvio, previsaoEntrega, dataEntrega) VALUES
    (1, 'EM_TRANSITO', 'BR123456789XX', 'Correios',   'Rua das Flores, 100 - Sao Paulo/SP',     NOW(), CURDATE() + INTERVAL 5 DAY, NULL),
    (2, 'PREPARANDO',  NULL,            NULL,         'Av. Atlantica, 200 - Rio de Janeiro/RJ', NULL,  NULL,                       NULL),
    (3, 'ENTREGUE',    'BR987654321YY', 'Jadlog',     'Rua da Industria, 300 - Campinas/SP',    NOW() - INTERVAL 4 DAY, CURDATE() - INTERVAL 1 DAY, NOW() - INTERVAL 1 DAY);
