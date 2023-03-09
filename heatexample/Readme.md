# Use the heat example

To test the heat-installation a heat-stack can be created by the following
command:

```
openstack stack create -t template.yaml -e environment.yaml Heat-Test \
  --parameter key_name=Lungo --parameter flavor=gx2.1c4r \
  --parameter image=188dbb00-681f-496b-af4a-430c4fc3bdbd
```

The parameters work fine in pileit; switch them out to match your platform :)

