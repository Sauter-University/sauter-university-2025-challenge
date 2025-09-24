# sauter-university-2025-challenge


![Architecture](./img/university.drawio.png)

Sobre o desafio: 

> Realizar a implementação vista na arquitetura acima;

Cada equipe se divida em grupos de 5 pessoas. Cada equipe precisará desenvolver o esquema apresentado na arquitetura, seguindo as boas práticas de engenharia de dados, de software e do Google Cloud.
Cada equipe deverá realizar uma demonstração PRÁTICA sobre a sua solução, pontuando explicitamente cada ponto destacado abaixo:
- Pitch, “Why Google?” (apresentação teórica de no máximo 3~5 minutos)

- Integração com a ferramenta de CI/CD (github actions);

- Terraform utilizado para levantar a infraestrutura;

- Pipeline de transformação dos dados;
REST API que buscará os dados para uma data específica ou um conjunto de dados históricos;

- Modelo preditivo que calcula o volume de água previsto para um reservatório (baseado no modelo de ENA)

> https://dados.ons.org.br/dataset/ear-diario-por-reservatorio

OU apresentar a criação de um agente com o ADK + Gemini, com mecanismo de RAG, que consulta a base de dados HISTÓRICA de ENA e é capaz de responder dúvidas sobre o volume de uma bacia hidrográfica em um determinado período, o agente também deve responder dúvidas sobre a sauter, baseado nos dados do site oficial da sauter http://sauter.digital. 
- Exibir em uma representação gráfica uma análise sobre os dados tratados.

### Critérios avaliados:

Além de todos os entregáveis acima, serão considerados:
- Boas práticas de Engenharia de Software, como a utilização de padrões de projeto ou a utilização indevida de um padrão de projeto.
- Boas práticas na construção de REST APIs.
TODOS os integrantes do grupo precisam realizar commits e especificar as branchs trabalhadas.
- Criação de budget alerts nos projetos, com custo máximo de 300 reais, e inclusão do email de ao menos 3 mentores como canal de envio, mais a equipe que construiu a solução, obrigatoriamente.
- Repositório Privado no github.
Utilização do workload identity federation.
Containerização da API.
- Documentação do código e docstrings.
Justificativa de escolha do tipo de gráfico para exibição dos dados.
- Utilizar obrigatoriamente a linguagem Python na criação da API.
- Apresentar os testes de unidade e testes de integração mockados com a api de dados abertos, com cobertura mínima de 85%.
- Para os grupos que escolherem criar o modelo preditivo, apresentar acurácia mínima de 70%, com testes nos conjuntos de dados, juntamente com a justificativa do modelo e das técnicas utilizadas.
- Para os grupos que escolherem criar um agente, será necessário apresentar a resposta lúcida do modelo, incluindo o prompt utilizado e a justificativa do modelo, como o testes e a orquestração de agentes;
- Explicitamente para as equipes que optarem pela criação de um agente, será necessário que o agente seja um “multi-agente”, ou seja, um orquestrador de outros agentes.
Os agentes obrigatórios serão:
Agente Orquestrador (root);
Agente que responde as perguntas sobre a ENA;
Agente que tira dúvidas sobre a sauter, consultando o site da Sauter (sauter.digital);

- modelo spotify 

- Geral de dados 
