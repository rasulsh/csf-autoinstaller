import os
import re

regex = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,7}\b'

def checkmail(email):
    if(re.fullmatch(regex, email)):
        return True
    return False

def find_package_manager():
    if os.path.exists('/usr/bin/yum'):
        return 'yum'
    elif os.path.exists('/usr/bin/dnf'):
        return 'dnf'
    elif os.path.exists('/usr/bin/apt'):
        return 'apt'
    else:
        return False

def package_installer(package_name):
    package_manager = find_package_manager()
    if not package_manager:
        print('Package manager not found')
        exit(1)
    if isinstance(package_name, list):
        for package in package_name:
            os.system('{} install -y {}'.format(package_manager, package))
    else:
        os.system('{} install -y {}'.format(package_manager, package_name))

def update_all_package(pkmanager):
    if pkmanager == 'yum':
        os.system('yum update -y')
    elif pkmanager == 'dnf':
        os.system('dnf update -y')
    elif pkmanager == 'apt':
        os.system('apt update -y')
    else:
        print('Package manager not found')
        exit(1)

def change_current_dir(new_dir):
    os.chdir(new_dir)

def run_command(command):
    os.system(command)

def get_bash_path():
    return os.environ['SHELL']

def replace_port_vars(file_content,var_name,append_values):
    for i, line in enumerate(file_content):
        if line.startswith(var_name):
            key, value = line.strip().split('=')
            ports = value.strip().strip('"').split(',')
            ports += append_values.split(',')
            updated_value = '"' + ','.join(ports) + '"'
            file_content[i] = f'{key} = {updated_value}\n'
            break
    return file_content

def configure_csf():
    # csf config file : /etc/csf/csf.conf
    with open('/etc/csf/csf.conf', 'r+') as f:
        # start config
        lines = f.readlines()
        lines[lines.index('TESTING = "1"\n')] = 'TESTING = "0"\n'
        lines[lines.index('RESTRICT_SYSLOG = "0"\n')] = 'RESTRICT_SYSLOG = "3"\n'
        lines[lines.index('DENY_TEMP_IP_LIMIT = "100"\n')] = 'DENY_TEMP_IP_LIMIT = "900"\n'
        lines[lines.index('LF_IPSET = "0"\n')] = 'LF_IPSET = "1"\n'
        lines[lines.index('LF_SELECT = "0"\n')] = 'LF_SELECT = "1"\n'
        lines[lines.index('CT_LIMIT = "0"\n')] = 'CT_LIMIT = "800"\n'
        lines[lines.index('PT_USERMEM = "512"\n')] = 'PT_USERMEM = "0"\n'
        lines[lines.index('PT_LIMIT = "60"\n')] = 'PT_LIMIT = "0"\n'
        lines[lines.index('PT_SKIP_HTTP = "0"\n')] = 'PT_SKIP_HTTP = "1"\n'
        lines[lines.index('LF_EMAIL_ALERT = "1"\n')] = 'LF_EMAIL_ALERT = "0"\n'
        lines[lines.index('LF_PERMBLOCK_ALERT = "1"\n')] = 'LF_PERMBLOCK_ALERT = "0"\n'

        
        read_administrator_email = input('Enter administrator email: ')
        
        if read_administrator_email == '' or checkmail(read_administrator_email) == False:
            print('>>>>>>>>> Administrator email is empty or invalid, skip')
        else:
            lines[lines.index('LF_ALERT_TO = ""\n')] = 'LF_ALERT_TO = "{}"\n'.format(read_administrator_email)
        
        read_custom_TCP_ports    = input('Enter custom TCP PORTS (seperate with english comma): ')

        if read_custom_TCP_ports == '':
            print('>>>>>>>>> Custom TCP ports is empty, skip')
        else:
            lines = replace_port_vars(lines,'TCP_IN',read_custom_TCP_ports)
            lines = replace_port_vars(lines,'TCP_OUT',read_custom_TCP_ports)

        read_custom_UDP_ports    = input('Enter custom UDP PORTS (seperate with english comma): ')

        if read_custom_UDP_ports == '':
            print('>>>>>>>>> Custom UDP ports is empty, skip')
        else:
            lines = replace_port_vars(lines,'UDP_IN',read_custom_UDP_ports)
            lines = replace_port_vars(lines,'UDP_OUT',read_custom_UDP_ports)

        
        # write config
        f.seek(0)
        f.writelines(lines)
        f.truncate()
        
        # end config
        f.close()

## Main
update_all_package(find_package_manager())

package_installer('tar wget nano')

change_current_dir('/tmp')

run_command('mkdir csfinstall')

change_current_dir('/tmp/csfinstall')

run_command('wget "https://download.configserver.com/csf.tgz"')

run_command('tar -xzf csf.tgz')

change_current_dir('/tmp/csfinstall/csf')

run_command('{} install.sh'.format(get_bash_path()))

package_installer([
    'perl-libwww-perl',
    'perl-LWP-Protocol-https',
    'perl-GDGraph',
    'liblwp-protocol-https-perl',
    'libgd-graph-perl',
    'perl-Crypt-SSLeay',
    'perl-Time-HiRes',
    'perl-Math-BigInt',
    'perl-Math-BigInt-GMP',
    'perl-Math-BigInt-FastCalc',
    'ipset'
])

configure_csf()

run_command('csf -x ; csf -e ; clear')
run_command('systemctl status lfd')
print('\n----------------------------------------------\n')
run_command('systemctl status csf')


# clear temporary files
run_command('rm -rf /tmp/csfinstall')