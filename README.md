## Ficha do projeto

- Tema do sistema: gestão de pedidos de camisas
- Quem usa o sistema: o vendedor que realiza a compra de camisas
- Entidade principal (singular): pedido
- Campos da entidade (com tipo e se é obrigatório): camisa_pedido (camisa_pedido); data_pedido (data); situacao (postado, em_transito, entregue); valor_pedido (float com duas casas decimais);
- Relacionamento com o usuário: as camisas ja cadastradas no sistema são inseridas no pedido que e atualizado ao longo do processo de entrega
- Como o usuário vai buscar/filtrar: buscar o pedido pela data de realizacao, valor do pedido, ou camisas que estejam no pedido
