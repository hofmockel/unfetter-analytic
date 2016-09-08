#!/usr/bin/env bash


try_install() {
    dpkg-query -W "$1" 2> /dev/null
    if [ $? -ne 0 ]; then
        echo "*** installing $1"
        sudo apt-get -y -q install "$@" 2>/dev/null
        return 0
    else 
        return 1
    fi      
}

wget -q -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add - 2>/dev/null


#Install Logstash
echo "*** Updating source packages for download"
echo 'deb http://packages.elasticsearch.org/logstash/2.3/debian stable main' | sudo tee /etc/apt/sources.list.d/logstash.list >/dev/null
echo 'deb http://packages.elastic.co/elasticsearch/2.x/debian stable main' | sudo tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list >/dev/null
echo 'deb http://packages.elastic.co/kibana/4.5/debian stable main' | sudo tee -a /etc/apt/sources.list.d/kibana-4.5.x.list >/dev/null
echo "*** Installing necessary packages"

sudo apt-get -qq update 2>/dev/null

# install java
try_install openjdk-7-jre-headless
try_install nginx 
try_install apache2-utils 

if try_install elasticsearch; then
    sudo update-rc.d elasticsearch defaults 95 10
    #sudo /usr/share/elasticsearch/bin/plugin install mobz/elasticsearch-head
	sudo /vagrant/resources/elasticsearch-head-installer.sh
    cp /vagrant/resources/elasticsearch.yml /etc/elasticsearch/
    sudo /etc/init.d/elasticsearch start
    sleep 10
else
    cp /vagrant/resources/elasticsearch.yml /etc/elasticsearch/
    sudo /etc/init.d/elasticsearch restart
fi

try_install unzip
if try_install logstash; then
    cp /vagrant/logstash_conf/* /etc/logstash/conf.d/
    sudo /opt/logstash/bin/plugin install logstash-filter-translate
    sudo update-rc.d logstash defaults 96 9
    sudo /etc/init.d/logstash start
else
    cp /vagrant/logstash_conf/* /etc/logstash/conf.d/
    sudo /etc/init.d/logstash restart
fi
if try_install kibana; then
    id -u kibana 2> /dev/null
	if [ $? -ne 0 ] ; then
        sudo groupadd -g 998 kibana
        sudo useradd -u 998 -g 998 kibana
	fi
    sudo cp /vagrant/resources/kibana.conf /etc/init.d/kibana
    sudo update-rc.d kibana defaults 96 9
    sudo cp /vagrant/resources/kibana.yml  /opt/kibana/config/kibana.yml
    sudo service kibana start
    sleep 10
else
    sudo service kibana restart
fi
/vagrant/resources/es_template.sh
cd /vagrant/resources
python load_dashboard.py

############################
# Install Scala
############################

if [ ! -d "/usr/local/scala" ]; then
    echo "*** Installing Scala"
    cd /tmp
    wget http://downloads.typesafe.com/scala/2.11.7/scala-2.11.7.tgz?_ga=1.204864528.1236579178.1455238364 -O scala-2.11.7.tgz -q
    tar -xf scala-2*.tgz
    mkdir /usr/local/scala
    mv scala-2*/* /usr/local/scala/
fi


############################
# Install Spark 
############################

if [ ! -d "/usr/local/spark" ]; then
    cd /tmp
     echo "*** Installing Spark"
    wget http://apache.mirrors.ionfish.org/spark/spark-1.6.1/spark-1.6.1-bin-hadoop2.6.tgz -q
    tar -xf spark-1.6*.tgz
    mkdir /usr/local/spark
    mv spark-1.6*/* /usr/local/spark/
    #This will quiet the INFO and WARN to console when testing.
    sudo cp /vagrant/resources/log4j.properties /usr/local/spark/conf
    sudo cp /vagrant/resources/spark-defaults.conf /usr/local/spark/conf
    cd /tmp
    wget http://download.elastic.co/hadoop/elasticsearch-hadoop-2.2.0-rc1.zip -q
    sudo mkdir /usr/local/spark/jars
    sudo unzip elasticsearch-hadoop-2*.zip 

    #sudo mv elasticsearch-hadoop-2.2.0-rc1/dist/elasticsearch-hadoop-2.2.0-rc1.jar /usr/local/spark/jars
    sudo mv elasticsearch-hadoop-2.2.0-rc1/dist/elasticsearch-hadoop-2.2.0-rc1.jar /usr/local/spark/jars
    sudo rm -r elasticsearch-hadoop*
fi

cp /vagrant/resources/.bashrc /home/vagrant/.bashrc
su vagrant
source /home/vagrant/.bashrc