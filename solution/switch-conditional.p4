/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<48> macAddr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

struct metadata {
    /* empty */
}

struct headers {
    ethernet_t   ethernet;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

      state start{
  	    packet.extract(hdr.ethernet);
        transition accept;
      }

}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    apply {
        macAddr_t PHONE_MAC = 0x000000000004;
        macAddr_t HOMEPC_MAC = 0x000000000002;
        macAddr_t ROUTER_MAC = 0x000000000005;
        macAddr_t TABLET_MAC = 0x000000000006;

        if (hdr.ethernet.dstAddr == HOMEPC_MAC) { // homePC
            standard_metadata.egress_spec = 2; // send to port 2
        } else if (hdr.ethernet.dstAddr == TABLET_MAC) { // tablet
            standard_metadata.egress_spec = 3; // send to port 3
        } else if (hdr.ethernet.dstAddr == PHONE_MAC) { // phone
            standard_metadata.egress_spec = 4; // send to port 4
        } else if (hdr.ethernet.dstAddr == ROUTER_MAC) { // router  
           standard_metadata.egress_spec = 1; // send to port 1 
        } else {
            // Drop packet if destination MAC is unknown
            mark_to_drop();
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
    apply { }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
		// parsed headers have to be added again into the packet
		packet.emit(hdr.ethernet);
	}
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
	MyParser(),
	MyVerifyChecksum(),
	MyIngress(),
	MyEgress(),
	MyComputeChecksum(),
	MyDeparser()
) main;