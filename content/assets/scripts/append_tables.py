import re

data = {
    "Default": {
        "master.cdp (10.0.0.2)": ["SPARK3_CLIENT", "YARN_CLIENT", "HDFS_CLIENT", "HISTORYSERVER", "INFRA_SOLR_CLIENT", "HBASE_MASTER", "NAMENODE", "TEZ_CLIENT", "ZOOKEEPER_CLIENT", "YARN_REGISTRY_DNS", "TIMELINE_READER", "RANGER_ADMIN", "SECONDARY_NAMENODE", "MAPREDUCE2_CLIENT", "ZOOKEEPER_SERVER", "AMBARI_SERVER", "HBASE_CLIENT", "INFRA_SOLR", "RANGER_USERSYNC", "APP_TIMELINE_SERVER", "HIVE_CLIENT", "SPARK3_JOBHISTORYSERVER", "PHOENIX_QUERY_SERVER", "RESOURCEMANAGER"],
        "node1.cdp (10.0.0.3)": ["NODEMANAGER", "SPARK3_CLIENT", "YARN_CLIENT", "HDFS_CLIENT", "HIVE_SERVER", "NFS_GATEWAY", "INFRA_SOLR_CLIENT", "HIVE_METASTORE", "NIFI_CA", "TEZ_CLIENT", "ZOOKEEPER_CLIENT", "KAFKA_BROKER", "MAPREDUCE2_CLIENT", "ZOOKEEPER_SERVER", "DATANODE", "HBASE_CLIENT", "NIFI_MASTER", "HIVE_CLIENT"],
        "node2.cdp (10.0.0.4)": ["NODEMANAGER", "SPARK3_CLIENT", "YARN_CLIENT", "HDFS_CLIENT", "INFRA_SOLR_CLIENT", "TEZ_CLIENT", "ZOOKEEPER_CLIENT", "KAFKA_BROKER", "MAPREDUCE2_CLIENT", "ZOOKEEPER_SERVER", "DATANODE", "HBASE_CLIENT", "SPARK3_THRIFTSERVER", "HIVE_CLIENT"],
        "node3.cdp (10.0.0.5)": ["NODEMANAGER", "SPARK3_CLIENT", "RANGER_TAGSYNC", "YARN_CLIENT", "HDFS_CLIENT", "SPARK3_LIVY2_SERVER", "INFRA_SOLR_CLIENT", "TEZ_CLIENT", "ZOOKEEPER_CLIENT", "KAFKA_BROKER", "MAPREDUCE2_CLIENT", "HBASE_REGIONSERVER", "DATANODE", "HBASE_CLIENT", "HIVE_CLIENT"]
    },
    "Data Science": {
        "master.cdp (10.0.0.2)": ["NAMENODE", "SECONDARY_NAMENODE", "RESOURCEMANAGER", "TIMELINE_READER", "YARN_REGISTRY_DNS", "APP_TIMELINE_SERVER", "HISTORYSERVER", "ZOOKEEPER_SERVER", "INFRA_SOLR", "RANGER_USERSYNC", "RANGER_ADMIN", "SPARK3_JOBHISTORYSERVER", "HDFS_CLIENT", "YARN_CLIENT", "MAPREDUCE2_CLIENT", "TEZ_CLIENT", "HIVE_CLIENT", "ZOOKEEPER_CLIENT", "INFRA_SOLR_CLIENT", "SPARK3_CLIENT"],
        "node1.cdp (10.0.0.3)": ["HIVE_METASTORE", "HIVE_SERVER", "ZOOKEEPER_SERVER", "KAFKA_BROKER", "DATANODE", "NFS_GATEWAY", "NODEMANAGER", "HDFS_CLIENT", "YARN_CLIENT", "MAPREDUCE2_CLIENT", "TEZ_CLIENT", "HIVE_CLIENT", "ZOOKEEPER_CLIENT", "INFRA_SOLR_CLIENT", "SPARK3_CLIENT"],
        "node2.cdp (10.0.0.4)": ["ZOOKEEPER_SERVER", "KAFKA_BROKER", "DATANODE", "NODEMANAGER", "SPARK3_THRIFTSERVER", "HDFS_CLIENT", "YARN_CLIENT", "MAPREDUCE2_CLIENT", "TEZ_CLIENT", "HIVE_CLIENT", "ZOOKEEPER_CLIENT", "INFRA_SOLR_CLIENT", "SPARK3_CLIENT"],
        "node3.cdp (10.0.0.5)": ["KAFKA_BROKER", "DATANODE", "NODEMANAGER", "RANGER_TAGSYNC", "SPARK3_LIVY2_SERVER", "HDFS_CLIENT", "YARN_CLIENT", "MAPREDUCE2_CLIENT", "TEZ_CLIENT", "HIVE_CLIENT", "ZOOKEEPER_CLIENT", "INFRA_SOLR_CLIENT", "SPARK3_CLIENT"]
    },
    "Software Engineering": {
        "master.cdp (10.0.0.2)": ["SECONDARY_NAMENODE", "NAMENODE", "APP_TIMELINE_SERVER", "RESOURCEMANAGER", "TIMELINE_READER", "YARN_REGISTRY_DNS", "HISTORYSERVER", "HBASE_MASTER", "ZOOKEEPER_SERVER", "PHOENIX_QUERY_SERVER", "HDFS_CLIENT", "YARN_CLIENT", "MAPREDUCE2_CLIENT", "HBASE_CLIENT", "ZOOKEEPER_CLIENT", "INFRA_SOLR"],
        "node1.cdp (10.0.0.3)": ["ZOOKEEPER_SERVER", "DATANODE", "NFS_GATEWAY", "NODEMANAGER", "NIFI_CA", "HDFS_CLIENT", "YARN_CLIENT", "MAPREDUCE2_CLIENT", "HBASE_CLIENT", "ZOOKEEPER_CLIENT"],
        "node2.cdp (10.0.0.4)": ["ZOOKEEPER_SERVER", "NIFI_MASTER", "DATANODE", "NODEMANAGER", "HDFS_CLIENT", "YARN_CLIENT", "MAPREDUCE2_CLIENT", "HBASE_CLIENT", "ZOOKEEPER_CLIENT"],
        "node3.cdp (10.0.0.5)": ["KAFKA_BROKER", "DATANODE", "NODEMANAGER", "HBASE_REGIONSERVER", "HDFS_CLIENT", "YARN_CLIENT", "MAPREDUCE2_CLIENT", "HBASE_CLIENT", "ZOOKEEPER_CLIENT"]
    }
}

fixes_dict = {
    "SPARK3": "Spark 3",
    "HBASE": "HBase",
    "HDFS": "HDFS",
    "HIVE": "Hive",
    "YARN": "YARN",
    "TEZ": "Tez",
    "NIFI": "NiFi",
    "KAFKA": "Kafka",
    "AMBARI": "Ambari",
    "ZOOKEEPER": "ZooKeeper",
    "DATANODE": "DataNode",
    "NAMENODE": "NameNode",
    "SECONDARY": "Secondary",
    "RESOURCEMANAGER": "ResourceManager",
    "NODEMANAGER": "NodeManager",
    "HISTORYSERVER": "HistoryServer",
    "REGISTRY": "Registry",
    "DNS": "DNS",
    "TIMELINE": "Timeline",
    "READER": "Reader",
    "APP": "App",
    "INFRA": "Infra",
    "SOLR": "Solr",
    "RANGER": "Ranger",
    "ADMIN": "Admin",
    "USERSYNC": "UserSync",
    "TAGSYNC": "TagSync",
    "MAPREDUCE2": "MapReduce2",
    "BROKER": "Broker",
    "SERVER": "Server",
    "CLIENT": "Client",
    "METASTORE": "Metastore",
    "CA": "CA",
    "MASTER": "Master",
    "THRIFTSERVER": "ThriftServer",
    "LIVY2": "Livy2",
    "REGIONSERVER": "RegionServer",
    "PHOENIX": "Phoenix",
    "QUERY": "Query",
    "NFS": "NFS",
    "GATEWAY": "Gateway",
    "JOBHISTORYSERVER": "JobHistoryServer"
}

def fmt_comp(c):
    parts = c.split('_')
    res = []
    for p in parts:
        res.append(fixes_dict.get(p, p.capitalize()))
    return " ".join(res)

latex = ["\\subsection{Data Lake Installation Profiles}"]
latex.append("The cluster provisioning process supports different deployment profiles customised for specific workloads. Based on the selected profile, Ambari will distribute the adequate components across the cluster nodes. The tables below detail the components present and the host responsibilities for each profile.")
latex.append("")

roles = {
    "master.cdp (10.0.0.2)": "Master Node (Cluster Management, Core Masters)",
    "node1.cdp (10.0.0.3)":  "Worker Node 1 (Data/Compute, specialized services)",
    "node2.cdp (10.0.0.4)":  "Worker Node 2 (Data/Compute, specialized services)",
    "node3.cdp (10.0.0.5)":  "Worker Node 3 (Data/Compute, specialized services)"
}

for profile, nodes in data.items():
    latex.append("\\begin{table}[htbp]")
    latex.append("  \\centering")
    latex.append(f"  \\caption{{Component Mapping for the {profile} Profile}}")
    safe_prof = profile.lower().replace(' ', '-')
    latex.append(f"  \\label{{tab:comp-{safe_prof}}}")
    # Decrease row separation internally for tighter fit
    latex.append("  \\renewcommand{\\arraystretch}{1.2}")
    latex.append("  \\begin{tabular}{l p{10cm}}")
    latex.append("    \\hline")
    latex.append("    \\textbf{Node & Role} & \\textbf{Installed Components} \\\\")
    latex.append("    \\hline")
    
    for i, (node, comps) in enumerate(nodes.items()):
        f_comps = [fmt_comp(c) for c in comps]
        f_comps.sort()
        # Separate master vs clients to make it readable, or just straight alphabetical
        c_str = ", ".join(f_comps)
        role = roles[node]
        latex.append(f"    \\textbf{{{node}}} & {c_str} \\\\")
        latex.append(f"    \\textit{{{role}}} & \\\\")
        if i < len(nodes) - 1:
            latex.append("    \\hline")
    
    latex.append("    \\hline")
    latex.append("  \\end{tabular}")
    latex.append("\\end{table}")
    latex.append("")

with open(r"c:\Users\joaop\Documents\cdp\cdp-article\content\04-Architecture-Design.tex", "a", encoding="utf-8") as f:
    f.write("\n" + "\n".join(latex) + "\n")

