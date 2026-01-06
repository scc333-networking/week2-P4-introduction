# SCC.333 Practical Exercise templates

This week's activity aims to introduce you to P4 programming by guiding you through the process of building a simple packet forwarding pipeline. This activity aims to support the lecture we will have this week on the P4 language and provide you with the hand-on experience of using SDN in practice. We will use the P4 throughpout this lab, so please do not simply copy and paste code during task, but rather try to understand the how and the why . By the end of this exercise, you will have a basic understanding of how to define packet headers, parse packets, and implement forwarding logic using P4. Our work will build upon the knowledge you gained from the Wireshark exercise earlier in the course. **If you have not completed that exercise, please do so before proceeding.**

By the end of this exercise, you will be able to:

- Understand the structure of network packets and their headers
- Define custom packet headers in P4
- Implement a basic packet parser
- Create a simple forwarding logic based on packet headers

## Task 0: Starting your 333 devcontainer environment

To simplify lab coding, we use a technology called containerisation, to package everything you need to run our lab activities in a pre-configured environment. You might have heard of Docker containers, which are lightweight, portable, and consistent virtual instances that can run applications and services.

In order to open the code in a devcontainer, you should select the options `Open In devcontainer` when opening the folder in VSCode. If you missed the option when openning the project, you can still setup the devcontainer. Use the key combination of Ctrl+Shift+P to open the command palette and then select **Dev Containers: Open Folder in Container...**. Both options are depicted in the screenshots below.

![Figure 3: Open devcontainer from popup](.resources/devcontainer-open-boot.png){width="5in"}

![Figure 4: Open devcontainer from action menu](.resources/devcontainer-menu.png){width="5in"}

If you have opened correctly the devcontainer, you should see the following prompt when opening a new terminal in VSCode:

![Figure 5: Devcontainer terminal prompt](.resources/homenet-router.png){width="5in"}

## Task 1: Running P4 programs in our home network scenario

For this first task, we will reuse the home network topology we used in the first week and replace the Linux Switch node with a P4 switch. The updated topology file will replace the home switch with a P4 switch, which we will use to host our custom P4 applications. 

![Figure 1: Home network topology with P4 switch](.resources/home-network-p4.png){width="5in"}

A P4 switch is a network device that allows a developer to realise and execute custom packet processing programs implemented using the P4 language. There are several P4 switch implementations out there, with some using real hardware to implement P4 pipeline, like the Barefoot Tofino. In this exercise, we will use the Stratum software switch, which is an open-source implementation of a P4 programmable switch. Stratum supports the P4 Runtime API, which allows us to program the switch using a P4 program using the GRPC protocol. The switch is designed to implement the P4 v1model architecture, which is a standard architecture for P4 programmable switches. It is not designed for high performance, but rather for learning and experimentation purposes.

The developers of the Stratum platform offer a Mininet Switch class called `Stratum`, contained in the file `p4_mininet/stratum.py`, which allows developers to run Stratum switches in their topology. This class extends the basic Mininet `Switch` class and adds all the functionality needed to run a P4 switch using the Stratum software switch. You can check the implementation of this class to understand how it works, **but you do not need to modify or understand the code it for this exercise**.

In order to add a P4 switch to the topology, you will have to modify the `mininet/topo.py` file. In this file, you will find the definition of the home network topology. You will have to replace the `LinuxSwitch` node with a `Stratum` node. You should replace you original switch definition, with the following code:

```python
s1 = self.addSwitch('s1', cls=StratumBmv2Switch, grpcPort=50001)
```
If you now run the topology using the command `make start`, you should see that the switch is started using the Stratum software switch. You can check the logs of the switch using the command `docker logs <container_id>`, where `<container_id>` is the ID of the switch container. You can find the container ID using the command `docker ps`. At the moment the switch is not doing anything, since we have not loaded any P4 program yet. In the next step, we will load a simple P4 program that makes the switch act as a packet repeater.

In order to simplify your interactions with the mininet topology and the P4 program, we have created a simple Makefile, which you should use to start and stop the topology, build your P4 program and opening the terminal to the mininet session. You can use the following commands to interact with the topology:

- `make start`: This command will start the mininet topology  defined in the file `mininet/topo.py`. 
- `make stop`: This command will stop the mininet topology and clean up all the resources used by the topology.
- `make p4build`: This command will compile the P4 program defined in the file `p4src/main.p4` and generate the necessary files to run the P4 program in the Stratum software switch. If you update your P4 program, you should first stop the topology using `make stop`, then run `make p4build` to compile the new program, and finally start the topology again using `make start`.
- `make clean`: Stop the topology and clean up all the resources used by the topology.

**You Goal for this task is to modify the topology file to use a P4 switch instead of a Linux switch and start the Mininet topology.** The switch offers a couple of ways to debug and troubleshoot its behaviour. Once the P4 switch has started, you will find a `tmp/` folder in your working directory. This folder contains the logs of the switch, which you can use to debug any issues you might have with your P4 program. If your P4 switch is loaded successfully, you should see a log file called `stratum_bmv2-<switch_name>.log`, where `<switch_name>` is the name of the switch in the topology (in our case `s1`). You can use the command `tail -f tmp/stratum_bmv2-s1.log` to follow the logs of the switch in real-time.

```
E0106 11:32:47.355383    88 main.cc:121] Starting bmv2 simple_switch and waiting for P4 pipeline
```

## Task 2: Introduction to P4 programming

P4 is a high-level programming language designed for programming packet processors, such as switches and routers. It allows developers to define how packets are processed and forwarded through the network. P4 is a domain-specific language that focuses on the data plane of network devices, allowing for flexible and programmable packet processing. In SCC.231 we have discussed the different types of network devices found in networks (e.g. switch, router, hub) and their functionalities. P4 tries to abstract the functionalities of these devices and provide a unified programming model for packet processing, which allows the same device to behave as a switch, router, firewall, etc. depending on the P4 program loaded into it.

The P4 language looks a lot like C, with similar syntax and constructs. However, P4 has some unique features that make it suitable for programming packet processors. Some of the key features of P4 include:

- **Data Types**: All data types in P4 are of fixed size, which allows for efficient packet processing. P4 supports basic data types such as `bit`, `int`, and `bool`, as well as complex data types such as `struct` and `header`. Some C types, like pointers, are not supported in P4.
- **Code Blocks**: Unlike C, P4 does not have functions. Instead, P4 uses code blocks to define the packet processing logic. Code blocks are similar to functions in C, but they do not have return values. A block has a specific purpose, such as parsing packets or processing packets, and this defines the type of parameters that a function can accept or return. The blocks are designed in such a way that they can be dropped in the processing pipeline of a hardware chip and be chained together to form a complete packet processing pipeline.
- **Control Flow**: P4 supports control flow constructs such as `if`, `else`, and `switch`, which allow developers to define complex packet processing logic. However, P4 does not support loops, as they can lead to unpredictable packet processing times.
- **Variables**: P4 supports variables, but they are limited in scope and lifetime. Variables can be defined within code blocks and are only accessible within that block. P4 does not support global variables or static variables.
- **Tables**: P4 provides a powerful abstraction for matching packet headers and performing actions on them. Tables can be defined with different match types (exact, ternary, longest prefix match) and can be populated with entries at runtime using the P4 Runtime API.

As part of the tutorial, we offer a skeleton P4 program located in the file `p4src/main.p4`. This program contains the basic structure of a P4 program, including header definitions, parser, and control blocks. Its functionality is limited and redirects all incoming packets to the same port they arrived on.


```C
#include <core.p4>
#include <v1model.p4>

typedef bit<48> macAddr_t;

struct metadata {
    /* empty */
}

struct headers {
}

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {
      state start{
          transition accept;
      }
}

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}


control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
       //Set Output port == Input port
       standard_metadata.egress_spec = standard_metadata.ingress_port;
    }
}

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
    apply { }
}

control MyDeparser(packet_out packet, in headers hdr) {
    apply { }
}

V1Switch(
	MyParser(),
	MyVerifyChecksum(),
	MyIngress(),
	MyEgress(),
	MyComputeChecksum(),
	MyDeparser()
) main;
```

this program is a minimal P4 program that defines a parser, control blocks, and a deparser. The parser and the deparser do not manipulate any headers from the incoming packets, but the control blocks do not perform any processing on the packets. Each block has a different set of input and output parameters, which are defined by the P4 architecture we are using (v1model). Furthermore, some input parameters are marked as `inout`, which means that they can be modified by the block. For example, the `standard_metadata` parameter in the `MyIngress` control block is marked as `inout`, which allows us to modify the `egress_spec` field to set the output port of the packet, otherwise the parameter is read-only. The key blocks and related parameters are the following:

- MyParser: This block is responsible for parsing the incoming packets and extracting the headers. It takes the following parameters:
  - `packet_in packet`: The incoming packet to be parsed. The packet is represented as a stream of bits that can be read and processed.
  - `out headers hdr`: The parsed headers extracted from the packet. The headers are defined in the `headers` struct and they are passed around the different blocks for processing.
  - `inout metadata meta`: Metadata associated with the packet (can be modified).
  - `inout standard_metadata_t standard_metadata`: These are metadata for the packet, defined by the switch. This metadata structure contains information from the switch about the packet, such as ingress port, and packet length, while individual blocks can modify  Some fields can be modified by the P4 program (e.g., egress port), while others are read-only.
- MyIngress: This block is responsible for processing the packets and making forwarding decisions. It takes the following parameters:
  - `inout headers hdr`: The parsed headers extracted from the packet. Header data can be modified in this block.
  - `inout metadata meta`: Metadata associated with the packet. Thist struct is writeable in this block and it is used to share information between different blocks.
  - `inout standard_metadata_t standard_metadata`: Metadata for the packet, defined by the switch (can be modified).
- MyDeparser: This block is responsible for reconstructing the packet after processing. It takes the following parameters:
  - `packet_out packet`: The outgoing packet to be constructed. The packet is represented as a stream of bits that can be written to.
  - `in headers hdr`: The parsed headers extracted from the packet. The headers are passed to this block for reconstruction.

The content of the `standard_metadata_t` struct is defined in the `v1model.p4` architecture file, which is included at the top of the P4 program. This struct contains several fields that are used by the switch to manage packet processing, such as `ingress_port`, `egress_spec`, `packet_length`, etc. You can find more information about the `standard_metadata_t` struct in the [P4 v1model architecture documentation](https://github.com/p4lang/behavioral-model/blob/main/docs/simple_switch.md).

```C
struct standard_metadata_t {
    PortId_t    ingress_port;
    PortId_t    egress_spec; // Used to set the output port when processing the packet in the ingress block
    PortId_t    egress_port; // Read-only port where the packet is sent out, accessible in egress control block
    bit<32>     instance_type;
    bit<32>     packet_length;
    //
    // queueing metadata - can be used to implement QoS
    bit<32> enq_timestamp;
    bit<19> enq_qdepth;
    bit<32> deq_timedelta;
    /// queue depth at the packet dequeue time.
    bit<19> deq_qdepth;

    // intrinsic metadata
    bit<48> ingress_global_timestamp;
    bit<48> egress_global_timestamp;
    /// multicast group id (key for the mcast replication table)
    bit<16> mcast_grp;
    /// Replication ID for multicast packets
    bit<16> egress_rid;
    /// Indicates that a verify_checksum() method has failed.
    /// 1 if a checksum error was found, otherwise 0.
    bit<1>  checksum_error;
    /// Error produced by parsing
    error parser_error;
    /// set packet priority
    bit<3> priority;
}
```


**Your goal for this task is to compile and load the P4 program on the P4 switch of your mininet topology.** As discussed in the previous task, in our Makefile we have defined a command `make p4build` that will compile the P4 program file `p4src/main.p4`. Try to run the command and check which files are generated in the `p4src/build` folder. This will create two files:

- `bmv2.json`: This file contains the compiled P4 program in JSON format, which is used by the Stratum software switch to configure the P4 pipeline.
- `p4info.txt`: This file contains details that can be used by the P4 Runtime controller to interact with the P4 program running in the switch. This is something that we will explore in more detail in future exercises.

### Understanding the P4 program structure

Lets start building our P4 program! In this exercise, you will learn how the basics of the P4 language and learn how to compile a P4 program using the SCC.333 pipeline. 

A P4 switch typically organizes its packet processing logic into several key components:

- **Header Definitions**: Define the structure of the packet headers that the switch will recognize and process.
- **Parser**: Extracts headers from incoming packets based on the defined header structures.
- **Match-Action Tables**: Define how packets are processed based on header fields, allowing for flexible forwarding and modification actions.
- **Control Blocks**: Orchestrate the overall packet processing flow, applying parsers and tables in a defined sequence.
- **Deparser**: Reconstructs packets for transmission after processing, ensuring they are correctly formatted.  

### P4 parser functions



## Task 3: Parsing an Ethernet packet

In the second introductory exercise we will use our first table and conditional statements in a control block. In this exercise you will make a two-port switch act as a packet repeater, in other words, when a packet enters port 1 it has to be leave from port 2 and vice versa.

To solve this exercise you only need to fill the gaps you will find in the repeater.p4 skeleton. The places where you are supposed to write your own code are marked with a TODO. You will have to solve this exercise using two different approaches (for the sake of learning). First, and since the switch only has 2 ports you will have to solve the exercise by just using conditional statements and fixed logic. For the second solution, you will have to use a match-action table and populate it using the CLI.

### Using Conditional Statements

1. Using conditional statements, write (in the `MyIngress` Control Block) the logic needed to make the switch act as a repeater. (only `TODO 3`)

### Using a Table

> If for the second solution you want to use a different program name and
> and topology file you can just define a new `p4` file and a different `.json`
> topology configuration, then you can run `sudo p4run --config <json file name>`.

1. Define a table of size 2, that matches packet's ingress_port and uses that to figure out which output port needs to be used (following the definition of repeater).

2. Define the action that will be called from the table. This action needs to set the output port. The type of `ingress_port` is `bit<9>`. For more info about the `standard_metadata` fields see: the [`v1model.p4`](https://github.com/p4lang/p4c/blob/master/p4include/v1model.p4) interface.

3. Call (by using `apply`), the table you defined above.

4. Populate the table (using the P4 Runtime controller provided by the script `controller.py`). For more information about table population check the following [documentation](https://github.com/nsg-ethz/p4-learning/wiki/Control-Plane).

## Testing your solution

Once you have the `repeater.p4` program finished you can test its behaviour:

1. Start the topology (this will also compile and load the program) using
   ```bash
   sudo p4run
   ```
   or
   ```bash
   sudo python network.py
   ```

2. Get a terminal in `h1` and `h2` using `mx`:

   ```bash
   mx h1
   mx h2 #in different terminal windows
   ```

   Or directly from the mininet prompt using `xterm`:

   ```
   mininet> xterm h1 h2
   ```

3. Run `receive.py` app in `h2`.

4. Run `send.py` in `h1`:

   ```bash
   python send.py 10.0.0.2 "Hello H2"
   ```

   The output at `h2` should be:

   <!-- <img src="images/h2_output.png" title="Receive Output"> -->

5. Since the switch will always forward traffic from `phone` to `router` and vice versa, we can test
the repeater with other applications such as: `ping`, `iperf`, etc. The mininet CLI provides some helpers
that make very easy such kind of tests:

   ```
   mininet> h1 ping h2
   ```

   ```
   mininet> iperf h1 h2
   ```

#### Some notes on debugging and troubleshooting

You should not have had any trouble with these first introductory exercises. However, as things get
more complicated you will most likely need to debug your programs and the behaviour of the switch and network.

We have added a [small guideline](https://github.com/nsg-ethz/p4-learning/wiki/Debugging-and-Troubleshooting) in the documentation section. Use it as a reference when things do not work as
expected.

# Task 2: Building a packet with P4

Before we dive into building our own switch, we need to take a closer look at packets — the fundamental units of communication in a network.
As we saw using Wireshark, hosts within a network communicate by sending and receiving packets. Each packet is made up of multiple headers, stacked on top of one another, followed by the actual data (payload) being transmitted.
Each header provides specific information about the packet, such as how it should be handled, where it’s coming from, and where it’s going. Understanding these headers is essential, because switches and routers rely on them to make forwarding decisions.

``` 
+-----------------------------+
| Ethernet Header (MAC)       |  ← Used by switches
+-----------------------------+
| IP Header (IP Address)      |  ← Used by routers
+-----------------------------+
| TCP / UDP Header            |  ← Used by applications
+-----------------------------+
| Payload (Actual Data)       |  ← Message, file, video, etc.
+-----------------------------+
```

## Packet headers
A network packet is built in layers, where each layer adds its own header. Not every packet contains all headers, but when present, each one serves a specific purpose.

### Ethernet Header (Layer 2 – Data Link)
- Purpose: Local delivery within a network
- Used by: Switches
- Contains:
    - Source MAC address – who sent the packet
    - Destination MAC address – who should receive it next
    - EtherType – indicates what protocol comes next (e.g., IPv4, IPv6, ARP)

> ‼️ This header is rewritten at every hop as packets move between networks.

### IP Header (Layer 3 – Network)
- Purpose: End-to-end delivery across networks
- Used by: Routers
- Contains:
    - Source IP address
    - Destination IP address
    - Protocol field (TCP, UDP, ICMP, etc.)
    - TTL (Time To Live) – prevents infinite looping
    - Packet length & fragmentation info

> ‼️ This header determines where the packet is going globally.

### Transport Layer Header (Layer 4)
This header contains information about how the packet is transmitted between applications on different hosts. It specifies the transport protocol being used (such as TCP or UDP) and includes the necessary details to manage communication, such as port numbers, delivery guarantees, and flow control.
#### TCP Header (Transmission Control Protocol)
- Purpose: Reliable, ordered delivery
- Used by: Web browsing, email, file transfer
- Contains:
    - Source & destination port numbers
    - Sequence & acknowledgment numbers
    - Flags (SYN, ACK, FIN)
    - Window size (flow control)

> ‼️ TCP ensures no data is lost or reordered.

#### UDP Header (User Datagram Protocol)
- Purpose: Fast, lightweight delivery
- Used by: Video streaming, gaming, VoIP
- Contains:
    - Source & destination port numbers
    - Packet length
    - Checksum

> ‼️ UDP is faster but does not guarantee delivery.

### ICMP Header (Control & Error Messages)
- Purpose: Network diagnostics and errors
- Used by: ping, traceroute
- Contains:
    - Type (e.g., echo request, destination unreachable)
    - Code (error details)

> ‼️ ICMP packets do not carry application data.

### Optional / Special Headers
Optional or special headers are not present in every packet. They are added only when specific network features or services are required. These headers allow networks to provide advanced functionality beyond basic packet forwarding, without changing the core packet structure.
#### VLAN Tag (802.1Q)
- Used for network segmentation
- Inserted between Ethernet header fields
#### MPLS Header
- Used in high-performance ISP networks
- Enables fast packet forwarding using labels
#### IPsec Headers
- Used for encryption and authentication
- Common in VPNs

### Application Layer Data (Payload)
- Purpose: Actual user data
- Examples:
    - HTTP request
    - Video stream
    - File contents
    - DNS query

> ‼️  Network devices usually do not inspect this, unless deep packet inspection is enabled.

<!-- ## Analogy: Sending a Letter
Think of a packet like mailing a letter:
- Ethernet header → Office mailroom instructions
- IP header → City and street address
- TCP/UDP header → Delivery instructions (urgent or careful)
- Payload → The letter itself

Each network device only reads the part it cares about! -->

## Why This Matters for P4 & SDN
Normally, switches and routers are like robots with fixed instructions:
> “I only understand Ethernet, IP, TCP… don’t ask me to do anything else.”
P4 changes that.

With P4, you get to say:
>“Hey switch, this is what a packet looks like, this is how I want you to read it, and this is what I want you to do with it.”

### In other words:
P4 = Programming Your Network Like a Game Character
- You define what headers exist
- You define how packets are processed
- You define what actions to take
- You control the rules of the game

### Why P4 Is Cool?
- You’re not stuck with predefined protocols
- You can build custom routers and switches
- You get full control over packet forwarding logic

### Analogy: A Custom Recipe
Traditional networking is like ordering from a fixed menu.

P4 lets you write your own recipe:
- Choose the ingredients (packet headers)
- Decide how to cook them (packet processing)
- Decide who gets served (forward, drop, modify)

## Getting started with P4

# Task 2: Building your very own switch with P4!
