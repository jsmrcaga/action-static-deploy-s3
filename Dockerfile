FROM python:3

ADD entrypoint.sh /entrypoint.sh
ADD action.yml /action.yml

RUN pip install --quiet --no-cache-dir awscli

ENTRYPOINT ["/entrypoint.sh"]
