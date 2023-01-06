__author__ = 'Michal Weis, AUTOCONT'



import sys

import ssl

from pyVim.connect import SmartConnect, Disconnect;

import argparse

import atexit

import vsanmgmtObjects

import vsanapiutils



# parameters

param_vicenter = (sys.argv[1])

param_user = (sys.argv[3])

param_pass = (sys.argv[4])

param_vsanCluster = (sys.argv[2])



# first argument

mode = (sys.argv[5])



# Get cluster instanace

def getClusterInstance(clusterName, serviceInstance):

   content = serviceInstance.RetrieveContent()

   searchIndex = content.searchIndex

   datacenters = content.rootFolder.childEntity

   for datacenter in datacenters:

      cluster = searchIndex.FindChild(datacenter.hostFolder, clusterName)

      if cluster is not None:

         return cluster

   return None



# get cluster Health

def GetClusterHealthSummary(cluster, vcMos):

 fetchFromCache = True

 vhs = vcMos['vsan-cluster-health-system']

 healthSummary = vhs.QueryClusterHealthSummary(

    cluster=cluster, includeObjUuids=True, fetchFromCache=fetchFromCache

 )

 clusterStatus = healthSummary.clusterStatus

 return clusterStatus



# get cluster isBalabcing

def GetIsRebalanceRunning(cluster, vcMos):

 fetchFromCache = True

 vhs = vcMos['vsan-cluster-health-system']

 healthSummary = vhs.IsRebalanceRunning (

    cluster=cluster

 )

 clusterStatus = healthSummary

 return clusterStatus





if sys.version_info[:3] > (2, 7, 8):

 context = ssl.create_default_context()

 context.check_hostname = False

 context.verify_mode = ssl.CERT_NONE



# Connect to vCenter Server or ESX

si = SmartConnect(

 host=param_vicenter,

 user=param_user,

 pwd=param_pass,

 port=int(443),

 sslContext=context)



# Disconnect from vSAN upon exit

atexit.register(Disconnect, si)



# Connect to the cluster passed as an argument

cluster = getClusterInstance(param_vsanCluster, si)

vcMos = vsanapiutils.GetVsanVcMos(si._stub, context=context)

status = GetClusterHealthSummary(cluster,vcMos)



returnData = '{"data":['



if mode == 'discovery':

   for host in status.trackedHostsStatus:

      returnData += '{"{#HOST}":"' + host.hostname + '"},'

   returnData += '{"{#HOST}":"' + param_vsanCluster + '"}'



if mode == 'status':

   returnData = '{"data":['

   for host in status.trackedHostsStatus:

      returnData += '{"' + host.hostname + '":"' + host.status + '"},'

   returnData += '{"' + param_vsanCluster + '":"' + status.status + '"}'



returnData += ']}'

print (returnData)

