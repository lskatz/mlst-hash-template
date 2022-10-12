extern crate md5;
//use md5;

use std::env;
use std::fs::File;
use std::io::prelude::*;
use std::io::BufReader;
//use std::io::{self, prelude::*, BufReader};

#[derive(Debug)]
struct Seq {
    id:  String,
    seq: String
}

fn main() {
    let mut args: Vec<String> = env::args().collect();

    let alleles_fh = File::create("alleles.tsv").expect("Writing to file alleles.tsv");
    let ref_fh     = File::create("ref.fasta").expect("writing to file ref.fasta");

    // Remove executable from args
    args.drain(0..1);
    for file in args{
      write_alleles(&file, &alleles_fh, &ref_fh);
    }
}

fn write_alleles(file:&str, mut alleles_fh:&File, mut ref_fh:&File) -> (){
    let seqs = read_fasta(file);

    let mut allele_counter:i32 = 0;

    for seq in seqs{
        let hashsum = md5::compute(&seq.seq);
        let hashsum_string = format!("{:X}", hashsum);
        let hashsum_64 = hex_to_base64(hashsum_string);

        // split the defline at _ so that we can get the locus and allele
        let locus_allele:Vec<&str> = seq.id.split("_").collect();

        if allele_counter == 0 {
            let ref_allele = format!(">{}\n{}\n", seq.id, seq.seq);
            ref_fh.write(ref_allele.as_bytes()).expect("Write bytes to references file");
        }

        let mut line = format!("{}", [
                locus_allele[0],
                &hashsum_64,
                "md5"
            ].join("\t")
        );
        line.push_str("\n");

        let bytes = line.as_bytes();

        alleles_fh.write(bytes).expect("Write bytes to alleles file");

        allele_counter += 1;
    }
    
}

fn read_fasta(file_str:&str) -> Vec<Seq> {
    let mut seqs:Vec<Seq> = vec![];
    let file = File::open(file_str).expect("Opening file for reading");
    let reader = BufReader::new(file);

    let mut id:String = String::from("undef");
    let mut sequence:String = String::from("undef");
    for line_res in reader.lines(){
        match line_res {
            Ok(line) => {
                if &line[0..1] == ">" {
                    seqs.push(Seq{id:id, seq:sequence});

                    sequence = String::new();
                    id = String::from(&line[1..]);
                }
                else{
                    sequence.push_str(&line);
                }
            }, 
            Err(e) => {eprintln!("Getting a line from file {}: {}", file_str, e);},
        }
    }

    seqs.drain(0..1);
    return seqs;
}


// https://stackoverflow.com/a/44532957
extern crate base64;
use std::u8;
use self::base64::{encode};

pub fn hex_to_base64(hex: String) -> String {

    // Make vector of bytes from octets
    let mut bytes = Vec::new();
    for i in 0..(hex.len()/2) {
        let res = u8::from_str_radix(&hex[2*i .. 2*i+2], 16);
        match res {
            Ok(v) => bytes.push(v),
            Err(e) => println!("Problem with hex: {}", e),
        };
    };
    let mut result = encode(&bytes); // now convert from Vec<u8> to b64-encoded String
    
    // remove padding chars
    while result.chars().last().unwrap() == '=' {
        result.pop();
    }
    
    result 
}    
