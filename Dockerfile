FROM alpine:latest


# Do not split this into multiple RUN!
# Docker creates a layer for every RUN-Statement
# therefore an 'apk delete build*' has no effect
RUN apk --no-cache --update add \
                            build-base \
                            ca-certificates \
                            curl \
                            ruby \
                            ruby-irb \
                            ruby-dev && \
    echo 'gem: --no-document' >> /etc/gemrc && \
    gem install fluentd -v 0.12.20 && \
    apk del build-base ruby-dev && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

RUN adduser -D -g '' -u 1000 -h /home/fluent fluent
RUN chown -R fluent:fluent /home/fluent

# for log storage (maybe shared with host)
RUN mkdir -p /fluentd/log
# configuration/plugins path (default: copied from .)
RUN mkdir -p /fluentd/etc /fluentd/plugins

RUN chown -R fluent:fluent /fluentd

USER fluent
WORKDIR /home/fluent

# Tell ruby to install packages as user
RUN echo "gem: --user-install --no-document" >> ~/.gemrc
ENV PATH /home/fluent/.gem/ruby/2.2.0/bin:$PATH
ENV GEM_PATH /home/fluent/.gem/ruby/2.2.0:$GEM_PATH



ENV FLUENTD_OPT=""
ENV FLUENTD_CONF="fluent.conf"





RUN fluent-gem install td
RUN gem install fluent-plugin-td
RUN gem install fluent-plugin-parser
RUN gem install fluent-plugin-elasticsearch
RUN gem install fluent-plugin-typecast


RUN mkdir -p /var/log
CMD exec fluentd -c /fluentd/etc/$FLUENTD_CONF -p /fluentd/plugins $FLUENTD_OPT


RUN curl -L https://github.com/sequenceiq/docker-alpine-dig/releases/download/v9.10.2/dig.tgz|tar -xzv -C /usr/local/bin/


EXPOSE 24224
