# Delete all LBaaS Healtmonitors
echo "Deleting all LBaaS Healthmonitors"
hms=$(neutron lbaas-healthmonitor-list -f value -c id)
for hm in $hms; do
  neutron lbaas-healthmonitor-delete $hm
done

# Delete all LBaaS Pools
echo "Deleting all LBaaS Pools"
pools=$(neutron lbaas-pool-list -f value -c id)
for pool in $pools; do
  neutron lbaas-pool-delete $pool
done

# Delete all LBaaS Listeners
echo "Deleting all LBaaS Listeners"
listeners=$(neutron lbaas-listener-list -f value -c id)
for listener in $listeners; do
  neutron lbaas-listener-delete $listener
done

# Delete all LBaaS Loadbalancers
echo "Deleting all LBaaS loadbalancers"
lbs=$(neutron lbaas-loadbalancer-list -f value -c id)
for lb in $lbs; do
  neutron lbaas-loadbalancer-delete $lb
done
