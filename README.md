# Algotrader

### (In progress) Deploy of a algorithmic stock trading strategy with a deep learning model (LSTM Keras) [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/drive/1_bsndj48XWm6H6cxDTaKKhBGTNuHgGLE?usp=sharing)
*Predicting Stock's price movement.*
> The main objectives of this project are: understand advanced deep learning models inner structures; comprehend the whole cycle of the data throughout a model in production.
The deploy of the model is going to be made in an AWS EC2 and it's going to be orchestraded with airflow.
<br />

![Image4](algotrader_flow.jpeg)
<br />
<br />

*I'm first developing a working stage of the project on colab to then gradually, while learning, move it to AWS in order to simulate a production environment. The current terraform script is already able to automatically build an airflow client on an AWS EC2 instance. The Airflow already has a DAG that first collects twitter data, creates a bucket and then sends the data to it.

Project built by personal motivation. Accompanied by mentors of the Data Engineering bootcamp at [How Bootcamps](https://howedu.com.br/cohort/engenharia-de-dados/?gclid=Cj0KCQiAmpyRBhC-ARIsABs2EAqENMpiYYuGn9bKLYI-btMdAS8R3be_UNzxraVEg4tDxT1Rkka8vRAaAsG5EALw_wcB).
<br />




