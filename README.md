# Controlador VGA para FPGA DE10-Lite (Altera MAX 10)

Este repositório contém um módulo controlador de VGA (`vga_sync.v`) otimizado e pronto para uso na placa de desenvolvimento **Terasic DE10-Lite**. 

**Aviso de Autoria:** Este módulo `vga_sync.v` é uma versão modificada baseada no original criado por jconenna, disponível em: https://github.com/jconenna/Yoshis-Nightmare/blob/master/source/vga_sync.v

O objetivo deste módulo é atuar como um "motor de vídeo" para a placa. Ele abstrai toda a complexidade dos tempos de varredura do monitor, permitindo que você foque **apenas em decidir qual cor pintar na tela** através de coordenadas (X, Y).

## Especificações Técnicas
* **Placa Alvo:** DE10-Lite (Intel/Altera MAX 10)
* **Resolução Suportada:** 640x480 pixels
* **Taxa de Atualização:** 60 Hz
* **Cores:** Suporte ao DAC nativo da placa com rede de resistores de 4-bits por cor (R, G, B).

---

## Entradas e Saídas do Módulo

O arquivo `vga_sync.v` possui as seguintes portas de comunicação com o seu projeto principal:

### Entradas (Inputs)
* `clk`: Clock nativo da placa. **Deve ser conectado diretamente ao pino de 50 MHz da DE10-Lite** (ex: `MAX10_CLK1_50`). O módulo já possui um divisor interno que o reduz para os 25 MHz exigidos pelo monitor.
* `reset`: Botão de reinicialização dos contadores (ativo em nível alto ou baixo, dependendo de como você mapear a chave/botão).

### Saídas (Outputs)
* `hsync`: Sinal de Sincronismo Horizontal. **Conecte ao pino VGA_HS** da placa.
* `vsync`: Sinal de Sincronismo Vertical. **Conecte ao pino VGA_VS** da placa.
* `video_on`: Sinal de habilitação (Sinalizador Visual). Ele vale `1` (Alto) quando o monitor está varrendo a área desenhável, e vale `0` (Baixo) quando o monitor está nas "margens escuras". Use este sinal para garantir que os gráficos só sejam acesos dentro da tela.
* `x [9:0]`: A Coordenada **X** (Coluna) atual que o monitor está desenhando (Varia de 0 a 639).
* `y [9:0]`: A Coordenada **Y** (Linha) atual que o monitor está desenhando (Varia de 0 a 479).
* `p_tick`: O "tick" (pulso) do pixel rodando a 25 MHz. Pode ser usado para sincronizar lógicas sequenciais externas.

---

## Como o VGA e o Sincronismo funcionam?

Os monitores antigos (e o padrão VGA) desenham a tela pixel por pixel, varrendo da esquerda para a direita, linha por linha, de cima para baixo.

Para que o monitor saiba quando mudar de linha ou voltar ao topo da tela, o módulo gera dois pulsos fundamentais:
1. **H-Sync (Sincronismo Horizontal):** Um pulso ativo em nível baixo que indica ao monitor que uma linha acabou e ele deve puxar o "feixe de luz" para o início da próxima linha.
2. **V-Sync (Sincronismo Vertical):** Um pulso ativo em nível baixo que indica o fim de um quadro (frame) inteiro, mandando o "feixe de luz" de volta para a coordenada (0,0) no canto superior esquerdo.

Além do tempo em que a tela está acesa (*Display interval*), existem as bordas escuras chamadas de **Front Porch** e **Back Porch**. É durante esses períodos que o sinal `video_on` fica em nível zero, para que o feixe de elétrons se reposicione sem manchar a tela. Nosso módulo já calcula tudo isso automaticamente.

---

## Como usar no seu Projeto (Exemplo de Instanciação)

Para desenhar algo na tela, basta instanciar o `vga_sync` no seu código principal (Top Level) e usar as coordenadas `x` e `y` para disparar as cores. A origem (0,0) fica no canto superior esquerdo.

Veja o exemplo abaixo de como instanciar o módulo e desenhar um quadrado amarelo na tela:

```verilog
module meu_projeto_top (
    input clk_50MHz,          // Clock de 50MHz da placa DE10-Lite
    input btn_reset,          // Botão de reset
    output VGA_HS, VGA_VS,    // Pinos de sincronismo do conector VGA
    output [3:0] VGA_R,       // Pinos Vermelhos (4 bits)
    output [3:0] VGA_G,       // Pinos Verdes (4 bits)
    output [3:0] VGA_B        // Pinos Azuis (4 bits)
);

    // Fios de interligação entre o controlador VGA e o nosso módulo
    wire [9:0] col_x, linha_y;
    wire area_visivel;

    // 1. Instanciar o Controlador VGA
    vga_sync controlador_vga (
        .clk(clk_50MHz),
        .reset(btn_reset),
        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .video_on(area_visivel),
        .x(col_x),
        .y(linha_y)
    );

    // 2. Lógica de desenho (Exemplo: Desenhar um quadrado entre as coordenadas 100 e 200)
    wire desenhar_quadrado;
    assign desenhar_quadrado = (col_x >= 100 && col_x <= 200) && (linha_y >= 100 && linha_y <= 200);

    // 3. Atribuição de Cores (Se estiver na área de desenho e dentro do quadrado, pinte de Amarelo)
    assign VGA_R = (area_visivel && desenhar_quadrado) ? 4'b1111 : 4'b0000;
    assign VGA_G = (area_visivel && desenhar_quadrado) ? 4'b1111 : 4'b0000;
    assign VGA_B = 4'b0000; // Azul desligado = Vermelho + Verde = Amarelo

endmodule 
```
