## Usage

###### configuration.yaml
```yaml
homeassistant:
  auth_providers:
    - type: command_line
      command: /absolute/path/to/script
      args:
        - 'https://ldap.example.com'
        - 'first_regular_user_group_in_lldap'
        - 'second_regular_user_group_in_lldap'
        - '--admin-group'
        - 'first_admin_user_group_in_lldap'
        - '--admin-group'
        - 'second_admin_user_group_in_lldap'
        - '--local-group'
        - 'first_local_only_group_in_lldap'
      meta: true
```