# Testar-conex-o-CPU-e-Mem-ria
Powershell focado em testar a conexão com um determinado host e o uso de CPU e Memória do client no momento do teste

O PowerShell em questão tem a seguinte utilidade:
Em um cenário de uma aplicação WEB que se conect a um servidor, se faz necessário testar a conexão com o servidor bem como a possibilidade do falso posítivo
do HOST caso o mesmo esteja consumindo recursos.
Por exemplo:
Em um aplicação IIS que possui pulso, e você possui muita queda da aplicação nos hosts, é possível testar a conexão do host com o servidor bem como bater a
confirmação se no momento da queda com o servidor havia gargalo no hardware que possa gerar a não resposta de pulso e como consequencia a queda do host

A parte mais prática é que o mesmo gera log no disco local C oque. Neste caso basta deixar o script rodando e aguardar o caso de queda ocorrer.
