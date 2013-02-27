name 'pi'
description 'pi base server role'

run_list 'recipe[apt]', 'recipe[openssh]'

override_attributes(openssh: {
                      permit_root_login: 'no',
                      password_authentication: 'no',
                      maxstartups: { start: 100, rate:  100, full:  100 }})