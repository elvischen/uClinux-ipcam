# This script was written by Javier Olascoaga <jolascoaga@sia.es>
# (C) SIA (http://www.sia.es)
#
# based on A. Tarasco <atarasco@sia.es> research.
# This script is releases under the GNU GPLv2 license.
#
# Fixes by Tenable:
#   - Changed text of description and report.
#   - Checked response and added another step in the 
#     initialization process to avoid false positives.
#   - Fixed bug that caused an empty banner in the report.


	desc["english"]= "
This script checks whether the remote host is running the Hacker
Defender backdoor. 

Hacker Defender is a rootkit for Windows.  Among other things, it hooks
itself into all open TCP ports on the system, listening for a
specially-crafted packet, and opening a backdoor on that port when
found.  This backdoor can be used by malicious users to control the
affected host remotely. 
	
Solution: Reinstall Windows.
Risk factor: Critical";



if (description) 
{
	script_id(15517);
	script_version ("$Revision: 1.8 $");

	name["english"] = "HACKER defender finder";
	script_name(english:name["english"]);

	script_description(english:desc["english"]);
	summary["english"] = "HACKER defender finder (All versions)";
	script_summary(english:summary["english"]);
	script_category(ACT_GATHER_INFO);
	script_copyright(english:"This script is Copyright (c) SIA 2004");
	script_family(english:"Backdoors");
	script_dependencie("os_fingerprint.nasl");
	exit (0);
}

os = get_kb_item("Host/OS/icmp");
if ( os && "Windows" >!< os ) exit(0);

list_ports[0] = 80;
list_ports[1] = 3389;
list_ports[2] = 21;
list_ports[3] = 25;
list_ports[4] = 7;
list_ports[5] = 1025;
list_ports[6] = 443;

max_ports = 6;

hx[0]=raw_string (0x01, 0x1e, 0x3c, 0x6c, 0x6a, 0xff, 0x99, 0xa8,0x34, 0x83, 0x38, 0x24, 0xa1, 0xa4, 0xf2, 0x11,0x5a, 0xd3, 0x18, 0x8d, 0xbc, 0xc4, 0x3e, 0x40,0x07, 0xa4, 0x28, 0xd4, 0x18, 0x48, 0xfe, 0x00);
hx_banner[0] = string("Hacker Defender v0.51-0.82b");

hx[1]=raw_string(0x01, 0x38, 0x45, 0x69, 0x3a, 0x1f, 0x44, 0x12,0x89, 0x55, 0x7f, 0xaa, 0xc0, 0x9f, 0xee, 0x61,0x3f, 0x9a, 0x7e, 0x84, 0x32, 0x04, 0x4e, 0x1d,0xd7, 0xe4, 0xa8, 0xc4, 0x48, 0xe8, 0x9e, 0x00);
hx_banner[1] = string("Hacker Defender v0.82-0.83");

hx[2]=raw_string(0x01, 0x9a, 0x8c, 0x66, 0xaf, 0xc0, 0x4a, 0x11,0x9e, 0x3f, 0x40, 0x88, 0x12, 0x2c, 0x3a, 0x4a,0x84, 0x65, 0x38, 0xb0, 0xb4, 0x08, 0x0b, 0xaf,0xdb, 0xce, 0x02, 0x94, 0x34, 0x5f, 0x22, 0x00);
hx_banner[2] = string("Hacker Defender v0.84-1.0.0");


for (i=0; i <= max_ports; i++) {
  # check list port

  if (get_port_state(list_ports[i])) 
  {
    soc = open_sock_tcp (list_ports[i]);
    if (soc) 
    {
      for (j=0;j<3;j++) {
        # nb: to understand this, look at the HandlerRoutine in 
        #     bdcli100.dpr in the Hacker Defender source.
        send (socket:soc, data: hx[j]);
        data = recv (socket:soc, length:128, timeout:1);
        if (data && strlen(data) == 1 && ord(data[0]) == 0xe0)
        {
          for (t=0; t<20; t++) {
            send (socket:soc, data: raw_string(0xe1));
            data = recv (socket:soc, length:1, timeout:1);
            if (data && strlen(data) == 1 && ord(data[0]) == 0xe2)
            {
              desc = ereg_replace(
                string:desc["english"],
                pattern:"This script[^\.]+\.",
                replace:string("The remote host is running the ", hx_banner[j], " backdoor.")
              );
              security_hole(data:desc, port:list_ports[i]);
              exit (0);
            }
          }
        }
      }
      close(soc);
    }
  }
}
