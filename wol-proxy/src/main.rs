use std::{env, io::Read, net::{TcpListener, TcpStream}};
use wol::send_wol;

fn main() {
    let listener = TcpListener::bind(env::var("LISTEN_ADDR").unwrap_or("127.0.0.1:9253".into())).unwrap();

    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                handle_connection(stream);
            }
            Err(e) => {
                eprintln!("Error accepting connection: {}", e);
            }
        }
    }
}

fn handle_connection(mut stream: TcpStream) {
    let mut buffer = [0; 1024];
    match stream.read(&mut buffer) {
        Ok(size) => {
            let request = String::from_utf8_lossy(&buffer[..size]);
            if request.trim() == "wake" {
                let mac_addr_raw = env::var("MAC_ADDR").unwrap_or("00:11:22:33:44:55".into());
                let mac_addr = match eui48::MacAddress::parse_str(&mac_addr_raw) {
                    Ok(mac) => mac,
                    Err(e) => {
                        eprintln!("Invalid MAC address format: {}", e);
                        return;
                    }
                };
                let result = send_wol(mac_addr.into(), None, None);

                if let Err(e) = result {
                    eprintln!("Error sending WOL packet: {}", e);
                } else {
                    println!("WOL packet sent to {}", mac_addr);
                }
            }
        }
        Err(e) => {
            eprintln!("Error reading from stream: {}", e);
        }
    }
}
