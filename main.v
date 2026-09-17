module main 

(
	 input clk_50MHz,          
    input btn_reset,          
    output VGA_HS, VGA_VS,    
    output [3:0] VGA_R,       
    output [3:0] VGA_G,       
    output [3:0] VGA_B        
);

    wire [9:0] eixo_x, eixo_y;
    wire area_visivel;

    // 1. Instancia do "motor"
    vga_sync meu_vga (clk_50MHz, ~btn_reset, VGA_HS, VGA_VS, area_visivel, , eixo_x, eixo_y);
    
	 
	 // 2.Matemática do Gráfico  (Literalmente a logica de desenho)
    // Exemplo: Quadrado amarelo no centro
    wire desenhar;
    assign desenhar = (eixo_x >= 300 && eixo_x <= 340) && (eixo_y >= 220 && eixo_y <= 260);

    // 3. Mandar sinal para os pinos de cor
    assign VGA_R = (area_visivel && desenhar) ? 4'b1111 : 4'b0000;
    assign VGA_G = (area_visivel && desenhar) ? 4'b1111 : 4'b0000;
    assign VGA_B = 4'b0000; 

endmodule