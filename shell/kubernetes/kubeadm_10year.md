kubeadm��ʼ��k8s��Ⱥ�ӳ�֤�����ʱ��

ǰ��
kubeadm��ʼ��k8s��Ⱥ��ǩ����CA֤����Ч��Ĭ����10�꣬ǩ����apiserver֤����Ч��Ĭ����1�꣬
����֮������apiserver�ᱨ��ʹ��openssl�����ѯ���֤���Ƿ��ڡ�

�����ӳ�֤����ڵķ����ʺ�kubernetes1.14��1.15��1.16��1.17��1.18�汾


�鿴֤����Чʱ��
[root@master01 ~]# openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -text  |grep Not

��ʾ���£�ͨ������ɿ���ca֤����Ч����10�꣬��2020��2030�꣺

Not Before: Apr 22 04:09:07 2020 GMT
Not After : Apr 20 04:09:07 2030 GMT


[root@master01 ~]#openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text  |grep Not
��ʾ���£�ͨ������ɿ���apiserver֤����Ч����1�꣬��2020��2021�꣺


Not Before: Apr 22 04:09:07 2020 GMT
Not After : Apr 22 04:09:07 2021 GMT

�ӳ�֤�����ʱ��
1.��update-kubeadm-cert.sh�ļ��ϴ���master1��master2��master3�ڵ�

update-kubeadm-cert.sh�ļ����ڵ�github��ַ���£�

https://github.com/luckylucky421/kubernetes1.17.3

��update-kubeadm-cert.sh�ļ�clone������������������master1��master2��master3�ڵ���


2.��ÿ���ڵ㶼ִ����������

1����update-kubeadm-cert.sh֤����Ȩ��ִ��Ȩ��

[root@master01 ~]#chmod +x update-kubeadm-cert.sh

2��ִ����������޸�֤�����ʱ�䣬��ʱ���ӳ���10��

[root@master01 ~]#./update-kubeadm-cert.sh all

3����master1�ڵ��ѯPod�Ƿ�����,�ܲ�ѯ������˵��֤��ǩ�����

[root@master01 ~]#kubectl  get pods -n kube-system


��ʾ���£��ܹ�����pod��Ϣ��˵��֤��ǩ��������

......
calico-node-b5ks5                  1/1     Running   0          157m
calico-node-r6bfr                  1/1     Running   0          155m
calico-node-r8qzv                  1/1     Running   0          7h1m
coredns-66bff467f8-5vk2q           1/1     Running   0          7h30m
......


��֤֤����Чʱ���Ƿ��ӳ���10��

[root@master01 ~]#openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -text  |grep Not

��ʾ���£�ͨ������ɿ���ca֤����Ч����10�꣬��2020��2030�꣺


Not Before: Apr 22 04:09:07 2020 GMT
Not After : Apr 20 04:09:07 2030 GMT
[root@master01 ~]#openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text  |grep Not

��ʾ���£�ͨ������ɿ���apiserver֤����Ч����10�꣬��2020��2030�꣺


Not Before: Apr 22 11:15:53 2020 GMT
Not After : Apr 20 11:15:53 2030 GMT
[root@master01 ~]#openssl x509 -in /etc/kubernetes/pki/apiserver-etcd-client.crt  -noout -text  |grep Not

��ʾ���£�ͨ������ɿ���etcd֤����Ч����10�꣬��2020��2030�꣺

Not Before: Apr 22 11:32:24 2020 GMT
Not After : Apr 20 11:32:24 2030 GMT
[root@master01 ~]#openssl x509 -in /etc/kubernetes/pki/front-proxy-ca.crt  -noout -text  |grep Not

��ʾ���£�ͨ������ɿ���fron-proxy֤����Ч����10�꣬��2020��2030�꣺


Not Before: Apr 22 04:09:08 2020 GMT
Not After : Apr 20 04:09:08 2030 GMT


























