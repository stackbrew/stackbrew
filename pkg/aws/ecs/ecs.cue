package ecs

import (
	"strconv"
	"strings"
	"encoding/json"

	"stackbrew.io/aws"
	"stackbrew.io/aws/cloudformation"
)

Container :: {
	Name:       string
	Image:      string
	Command:    [...string]
	Essential?: bool
	Environment?: [...{
		Name: string
		Value: string
	}]
	PortMappings?: [...{
		ContainerPort?: uint
		HostPort?:      uint
		Protocol?:      string
	}]
	LogConfiguration?: {
		LogDriver: *"awslogs" | string
		Options: [string]: string
	}
	HealthCheck?: {
		Command: [...string]
		Timeout?:     uint
		Interval?:    uint
		Retries?:     uint
		StartPeriod?: uint
	}
}

Task :: {
	cpu:         *256 | uint
	memory:      *512 | uint
	networkMode: *"bridge" | string
	containers: [...Container]
	roleArn?: string

	resources: ECSTaskDefinition: {
		Type: "AWS::ECS::TaskDefinition"
		Properties: {
			Cpu:    strconv.FormatUint(cpu, 10)
			Memory: strconv.FormatUint(memory, 10)
			if (roleArn & string) != _|_ {
				TaskRoleArn: roleArn
			}
			NetworkMode:          networkMode
			ContainerDefinitions: containers
		}
	}
}

Service :: {
	config: aws.Config

	// ECS cluster name or ARN
	cluster: string

	// Container port
	containerPort: uint

	// Container name
	containerName: string

	// Desired count
	desiredCount?: uint

	// Service launch type
	launchType: "FARGATE" | "EC2"

	// VPC id of the cluster
	vpcID: string

	// ARN of the ELB listener
	elbListenerArn: string

	// ELB rule priority
	elbRulePriority: uint | *100

	// Hostname of the publicly accessible service
	hostName: string

	// Name of the service
	serviceName: string

	resources: {
		ECSListenerRule: {
			Type: "AWS::ElasticLoadBalancingV2::ListenerRule"
			Properties: {
				ListenerArn: elbListenerArn
				Priority:    elbRulePriority
				Conditions: [{
					Field: "host-header"
					Values: [hostName]
				}]
				Actions: [{
					Type: "forward"
					TargetGroupArn: Ref: "ECSTargetGroup"
				}]
			}
		}

		ECSTargetGroup: {
			Type: "AWS::ElasticLoadBalancingV2::TargetGroup"
			Properties: {
				VpcId:    vpcID
				Port:     80
				Protocol: "HTTP"
			}
		}

		ECSService: {
			Type: "AWS::ECS::Service"
			Properties: {
				Cluster:      cluster
				DesiredCount: desiredCount
				LaunchType:   launchType
				LoadBalancers: [{
					TargetGroupArn: Ref: "ECSTargetGroup"
					ContainerName: containerName
					ContainerPort: containerPort
				}]
				ServiceName: serviceName
				TaskDefinition: Ref: "ECSTaskDefinition"
				DeploymentConfiguration: {
					MaximumPercent:        100
					MinimumHealthyPercent: 50
				}
			}
			DependsOn: "ECSListenerRule"
		}
	}
}

// SimpleECSApp is a simplified interface for ECS
SimpleECSApp :: {
	inputConfig=config:               aws.Config
	hostname:                         string
	containerImage:                   string
	inputContainerPort=containerPort: *80 | uint
	infra: {
		cluster:        string
		vpcID:          string
		elbListenerArn: string
	}
	subDomain: strings.Split(hostname, ".")[0]
	out:       cfn.stackOutput

	resources: {
		(Task & {
			containers: [Container & {
				Name:      subDomain
				Image:     containerImage
				Essential: true
				PortMappings: [{
					ContainerPort: inputContainerPort
					Protocol:      "tcp"
				}]
			}]
		}).resources

		(Service & {
			cluster:        infra.cluster
			containerPort:  inputContainerPort
			containerName:  subDomain
			desiredCount:   1
			launchType:     "EC2"
			vpcID:          infra.vpcID
			elbListenerArn: infra.elbListenerArn
			hostName:       hostname
			serviceName:    subDomain
		}).resources
	}

	cfn: cloudformation.Stack & {
		config: inputConfig
		source: json.Marshal({
			AWSTemplateFormatVersion: "2010-09-09"
			Description:              "ECS App deployed with Blocklayer"
			Resources:                resources
		})
		stackName: "bl-ecs-\(subDomain)"
	}
}
