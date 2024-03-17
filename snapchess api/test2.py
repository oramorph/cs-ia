import ngrok

try:
    client.ip_policies.get(id)
except ngrok.NotFoundError as e:
    client.ip_policies.create()
except ngrok.Error as e:
    # something else happened