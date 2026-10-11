FROM ruby:3.4.2-alpine AS download

WORKDIR /fonts

RUN apk --no-cache add fontforge wget unzip && \
    wget https://github.com/satbyy/go-noto-universal/releases/download/v7.0/GoNotoKurrent-Regular.ttf && \
    wget https://github.com/satbyy/go-noto-universal/releases/download/v7.0/GoNotoKurrent-Bold.ttf && \
    wget https://github.com/impallari/DancingScript/raw/master/fonts/DancingScript-Regular.otf && \
    wget https://cdn.jsdelivr.net/gh/notofonts/notofonts.github.io/fonts/NotoSansSymbols2/hinted/ttf/NotoSansSymbols2-Regular.ttf && \
    wget https://github.com/Maxattax97/gnu-freefont/raw/master/ttf/FreeSans.ttf && \
    wget https://github.com/impallari/DancingScript/raw/master/OFL.txt && \
    wget -O LICENSE https://raw.githubusercontent.com/notofonts/noto-fonts/refs/heads/main/LICENSE && \
    wget -O pdfium-linux.zip \
      "https://github.com/docusealco/pdfium-binaries/releases/download/20260920/pdfium-musl-$(uname -m).zip" && \
    case "$(uname -m)" in \
      x86_64) echo "bbca8a648dbd1ba81f9c6c223f21dc394cf1ad381c6c17d60c6dcc4a7d3a2ae0  pdfium-linux.zip" | sha256sum -c - ;; \
      aarch64) echo "73b72ed79b9bfdd494dee7e863482c24971a8d4b11f6cd1289aa170d31304a1f  pdfium-linux.zip" | sha256sum -c - ;; \
      *) echo "Unsupported CPU architecture: $(uname -m)" >&2; exit 1 ;; \
    esac && \
    mkdir -p /pdfium-linux && \
    unzip -q pdfium-linux.zip -d /pdfium-linux

RUN fontforge -lang=py -c \
    'font1 = fontforge.open("FreeSans.ttf"); font2 = fontforge.open("NotoSansSymbols2-Regular.ttf"); font1.mergeFonts(font2); font1.generate("FreeSans.ttf")'


FROM ruby:3.4.2-alpine AS webpack

ENV RAILS_ENV=production
ENV NODE_ENV=production

WORKDIR /app

RUN apk add --no-cache nodejs yarn git build-base && \
    gem install shakapacker -v 8.0.2 --no-document

COPY package.json yarn.lock ./

RUN yarn install --network-timeout 1000000

COPY bin/shakapacker ./bin/shakapacker
COPY config/webpack ./config/webpack
COPY config/shakapacker.yml ./config/shakapacker.yml
COPY postcss.config.js ./postcss.config.js
COPY tailwind.config.js ./tailwind.config.js
COPY tailwind.form.config.js ./tailwind.form.config.js
COPY tailwind.application.config.js ./tailwind.application.config.js
COPY app/javascript ./app/javascript
COPY app/views ./app/views

RUN echo "gem 'shakapacker'" > Gemfile && ./bin/shakapacker


FROM ruby:3.4.2-alpine AS app

ENV RAILS_ENV=production
ENV BUNDLE_WITHOUT="development:test"
ENV LD_PRELOAD=/lib/libgcompat.so.0
ENV OPENSSL_CONF=/app/openssl_legacy.cnf

WORKDIR /app

RUN apk add --no-cache \
    sqlite-dev libpq-dev mariadb-dev yaml-dev \
    vips-dev vips-poppler poppler-utils \
    libheif vips-heif gcompat font-freefont fontconfig && \
    mkdir -p /fonts && \
    rm -f /usr/share/fonts/freefont/FreeSans.otf

RUN addgroup -g 2000 docuseal && \
    adduser -u 2000 -G docuseal -s /bin/sh -D \
      -h /home/docuseal docuseal

RUN printf '%s\n' \
    '.include = /etc/ssl/openssl.cnf' \
    '' \
    '[provider_sect]' \
    'default = default_sect' \
    'legacy = legacy_sect' \
    '' \
    '[default_sect]' \
    'activate = 1' \
    '' \
    '[legacy_sect]' \
    'activate = 1' > /app/openssl_legacy.cnf

COPY Gemfile Gemfile.lock ./

RUN gem install bundler -v 2.5.3 --no-document && \
    apk add --no-cache build-base git && \
    bundle _2.5.3_ install --jobs 1 --retry 3 && \
    apk del --no-cache build-base git && \
    rm -rf /root/.bundle /usr/local/bundle/cache

COPY --chown=docuseal:docuseal bin ./bin
COPY --chown=docuseal:docuseal app ./app
COPY --chown=docuseal:docuseal config ./config
COPY --chown=docuseal:docuseal db ./db
COPY --chown=docuseal:docuseal log ./log
COPY --chown=docuseal:docuseal lib ./lib
COPY --chown=docuseal:docuseal public ./public
COPY --chown=docuseal:docuseal tmp ./tmp
COPY --chown=docuseal:docuseal LICENSE README.md Rakefile config.ru .version ./

COPY .version ./public/version

COPY --from=download \
    /fonts/GoNotoKurrent-Regular.ttf \
    /fonts/GoNotoKurrent-Bold.ttf \
    /fonts/DancingScript-Regular.otf \
    /fonts/OFL.txt \
    /fonts/LICENSE \
    /fonts/

COPY --from=download /fonts/FreeSans.ttf /usr/share/fonts/freefont/FreeSans.ttf
COPY --from=download /pdfium-linux/lib/libpdfium.so /usr/lib/libpdfium.so
COPY --from=download /pdfium-linux/licenses/ /usr/lib/libpdfium-licenses/
COPY --from=webpack /app/public/packs ./public/packs

RUN ln -s /fonts /app/public/fonts && \
    mkdir -p /app/tmp/cache /data/docuseal && \
    chown -R docuseal:docuseal /app/tmp /data/docuseal

ENV HOME=/home/docuseal
ENV WORKDIR=/data/docuseal
ENV VIPS_MAX_COORD=17000
ENV VIPS_BLOCK_UNTRUSTED=1

WORKDIR /data/docuseal

EXPOSE 3000

USER docuseal

CMD ["/app/bin/bundle", "exec", "puma", "-C", "/app/config/puma.rb", "--dir", "/app"]
