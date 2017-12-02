FROM rabbitmq:3.6.14-management-alpine

# Install required system packages and dependencies
ADD extras/rabbitmq_delayed_message_exchange-0.0.1.ez /plugins
ADD extras/definitions.json /etc/rabbitmq
ADD extras/rabbitmq.config /etc/rabbitmq
RUN rabbitmq-plugins enable rabbitmq_stomp rabbitmq_delayed_message_exchange --offline

EXPOSE 4369 5672 25672 15672 61613
