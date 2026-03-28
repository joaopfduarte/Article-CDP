import pandas as pd
import matplotlib.pyplot as plt
import os

# Caminho para o CSV
csv_path = '/home/duarte/Documents/cdp/cdp-article/content/assets/scripts/results.csv'
output_path = '/home/duarte/Documents/cdp/cdp-article/content/assets/graphic.pdf'

def gerar_grafico():
    print(f"Lendo dados de {csv_path}...")
    df = pd.read_csv(csv_path)

    # Pegar as queries únicas e garantir a ordem numérica (Q1, ..., Q14)
    queries = df['Query'].unique()
    queries = sorted(queries, key=lambda x: int(x[1:]))

    # Configuração de estilo geral para lembrar artigos acadêmicos
    plt.style.use('seaborn-v0_8-whitegrid')
    fig, ax = plt.subplots(figsize=(10, 5))

    # Dicionários de estilo mapeando as Engines
    colors = {'Hive': '#e74c3c', 'Spark': '#3498db', 'Spark_Cache': '#2ecc71'}
    labels = {'Hive': 'Apache Hive', 'Spark': 'Apache Spark', 'Spark_Cache': 'Spark In-Memory (Cache)'}
    markers = {'Hive': 's', 'Spark': '^', 'Spark_Cache': 'o'}

    # Iterar pelas engines para traçar as curvas com sombreamento ou barra de erro
    for engine in ['Hive', 'Spark', 'Spark_Cache']:
        # Filtrar o DataFrame e ordenar pelas queries corretas
        df_engine = df[df['Engine'] == engine].set_index('Query').reindex(queries)
        
        # Valores
        means = df_engine['Media_Simulada']
        stds = df_engine['Desvio_Padrao']
        
        # Plot com barras de desvio padrão
        ax.errorbar(
            queries, 
            means, 
            yerr=stds,
            label=labels[engine],
            color=colors[engine],
            marker=markers[engine],
            capsize=4,
            capthick=1.5,
            linewidth=2,
            markersize=7,
            elinewidth=1.5
        )

    # Configurações de título e rótulos
    ax.set_title('Query Execution Time Comparison: Hive vs. Spark vs. Spark In-Memory', fontsize=12, pad=15)
    ax.set_xlabel('SSB Queries', fontsize=11)
    ax.set_ylabel('Execution Time (seconds)', fontsize=11)
    
    # Grid e Legend
    ax.grid(True, linestyle='--', alpha=0.6)
    ax.legend(title='Processing Engine', fontsize=10, title_fontsize=10)
    
    # Ajuste de Layout
    plt.tight_layout()

    # Salva o arquivo em PDF
    plt.savefig(output_path, format='pdf', bbox_inches='tight')
    print(f"Gráfico gerado com sucesso em: {output_path}")

if __name__ == '__main__':
    gerar_grafico()
