FROM rust:1.89.0 as builder
WORKDIR /usr/src/app
COPY . .
RUN cargo build --release

FROM debian:bookworm-slim as runtime
COPY --from=builder /usr/src/app/target/release/wol-proxy /usr/local/bin/
EXPOSE 9253
CMD ["wol-proxy"]