sudo rm /etc/logstash/conf.d/*
sudo cp /vagrant/logstash_conf/* /etc/logstash/conf.d/
sudo service logstash restart
