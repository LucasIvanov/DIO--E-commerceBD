USE ecommerce;

-- 1) Clientes com seu tipo e documento (PF ou PJ, nunca os dois)
SELECT c.idCliente,
       c.tipo,
       COALESCE(CONCAT(pf.nome, ' ', pf.sobrenome), pj.razaoSocial) AS nome_ou_razao_social,
       COALESCE(pf.cpf, pj.cnpj)                                    AS documento
FROM cliente c
LEFT JOIN cliente_pf pf ON pf.idCliente = c.idCliente
LEFT JOIN cliente_pj pj ON pj.idCliente = c.idCliente;

-- 2) Formas de pagamento cadastradas por cliente
SELECT c.email,
       COUNT(fp.idFormaPagamento) AS qtd_formas_pagamento,
       GROUP_CONCAT(fp.tipo ORDER BY fp.tipo) AS formas
FROM cliente c
LEFT JOIN forma_pagamento fp ON fp.idCliente = c.idCliente AND fp.ativo
GROUP BY c.idCliente, c.email;

-- 3) Pedidos pagos com mais de uma forma de pagamento
SELECT p.idPedido,
       COUNT(pg.idPagamento) AS qtd_pagamentos,
       SUM(pg.valor)         AS total_pago
FROM pedido p
JOIN pagamento pg ON pg.idPedido = p.idPedido
GROUP BY p.idPedido
HAVING COUNT(pg.idPagamento) > 1;

-- 4) Acompanhamento de entrega: status e codigo de rastreio por pedido
SELECT p.idPedido,
       p.status          AS status_pedido,
       e.status          AS status_entrega,
       e.codigoRastreio,
       e.transportadora,
       e.previsaoEntrega
FROM pedido p
JOIN entrega e ON e.idPedido = p.idPedido
ORDER BY p.idPedido;

-- 5) Valor total de cada pedido (itens + frete) x total efetivamente pago
SELECT p.idPedido,
       SUM(i.quantidade * i.precoUnitario) + p.frete AS total_pedido,
       (SELECT COALESCE(SUM(pg.valor), 0)
          FROM pagamento pg
         WHERE pg.idPedido = p.idPedido AND pg.status = 'APROVADO') AS total_pago
FROM pedido p
JOIN item_pedido i ON i.idPedido = p.idPedido
GROUP BY p.idPedido, p.frete;

-- 6) Estoque disponivel por produto
SELECT pr.nome, SUM(pe.quantidade) AS qtd_em_estoque
FROM produto pr
JOIN produto_estoque pe ON pe.idProduto = pr.idProduto
GROUP BY pr.idProduto, pr.nome;

-- ---------------------------------------------------------------------
-- Testes de integridade (cada comando abaixo DEVE falhar)
-- ---------------------------------------------------------------------

-- a) Cliente PF nao pode ganhar tambem um registro PJ
-- INSERT INTO cliente_pj (idCliente, razaoSocial, cnpj) VALUES (1, 'Maria ME', '55555555000155');

-- b) Cliente PJ nao pode ganhar registro PF
-- INSERT INTO cliente_pf (idCliente, nome, sobrenome, cpf) VALUES (3, 'Teste', 'Teste', '33333333333');

-- c) Pagar o pedido da Maria (cliente 1) com a forma de pagamento do Joao (cliente 2)
-- INSERT INTO pagamento (idPedido, idFormaPagamento, idCliente, valor) VALUES (1, 4, 1, 10.00);

-- d) Entrega postada sem codigo de rastreio
-- UPDATE entrega SET status = 'POSTADO' WHERE idPedido = 2;
