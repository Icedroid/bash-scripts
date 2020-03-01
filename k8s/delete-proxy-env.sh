#!/bin/bash

kubectl -n kube-system edit daemonset kube-proxy
kubectl -n kube-system patch --type json daemonset kube-proxy -p "$(
    cat <<EOF
[	
    {	
        "op": "add",	
        "path": "/spec/template/spec/containers/0/env",	
        "value": [	
            {	
                "name": "NODE_NAME",	
                "valueFrom": {	
                    "fieldRef": {	
                        "apiVersion": "v1",	
                        "fieldPath": "spec.nodeName"	
                    }	
                }	
            }	
        ]	
    }
]	
EOF
)"
