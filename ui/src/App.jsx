import { useEffect, useState } from 'react'

// All calls go through the API Gateway (Path: /api/**), never directly
// to order-service or inventory-service. That single ingress point is
// what k8s/stage1-gke/ingress.yaml exposes to the outside world later.

export default function App() {
  const [orders, setOrders] = useState([])
  const [inventory, setInventory] = useState([])
  const [form, setForm] = useState({ sku: '', quantity: 1, customerEmail: '' })
  const [error, setError] = useState(null)

  const loadOrders = () =>
    fetch('/api/orders').then(r => r.json()).then(setOrders).catch(e => setError(String(e)))

  const loadInventory = () =>
    fetch('/api/inventory').then(r => r.json()).then(setInventory).catch(e => setError(String(e)))

  useEffect(() => { loadOrders(); loadInventory() }, [])

  const submitOrder = async (e) => {
    e.preventDefault()
    setError(null)
    try {
      const res = await fetch('/api/orders', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...form, quantity: Number(form.quantity) })
      })
      if (!res.ok) throw new Error(`Order failed: ${res.status}`)
      setForm({ sku: '', quantity: 1, customerEmail: '' })
      await loadOrders()
      setTimeout(loadInventory, 1000) // give the async consumer a moment
    } catch (err) {
      setError(String(err))
    }
  }

  return (
    <div style={{ fontFamily: 'sans-serif', maxWidth: 720, margin: '2rem auto' }}>
      <h1>OrderFlow</h1>
      <p style={{ color: '#666' }}>UI -&gt; API Gateway -&gt; Order Service -&gt; RabbitMQ -&gt; Inventory / Notification</p>

      {error && <p style={{ color: 'crimson' }}>{error}</p>}

      <h2>Place an order</h2>
      <form onSubmit={submitOrder} style={{ display: 'grid', gap: 8, maxWidth: 360 }}>
        <input placeholder="SKU" value={form.sku}
               onChange={e => setForm({ ...form, sku: e.target.value })} required />
        <input type="number" min="1" placeholder="Quantity" value={form.quantity}
               onChange={e => setForm({ ...form, quantity: e.target.value })} required />
        <input type="email" placeholder="Customer email" value={form.customerEmail}
               onChange={e => setForm({ ...form, customerEmail: e.target.value })} required />
        <button type="submit">Place order</button>
      </form>

      <h2>Orders</h2>
      <table width="100%" cellPadding="6">
        <thead><tr><th align="left">ID</th><th align="left">SKU</th><th align="left">Qty</th><th align="left">Status</th></tr></thead>
        <tbody>
          {orders.map(o => (
            <tr key={o.id}><td>{o.id}</td><td>{o.sku}</td><td>{o.quantity}</td><td>{o.status}</td></tr>
          ))}
        </tbody>
      </table>

      <h2>Inventory</h2>
      <table width="100%" cellPadding="6">
        <thead><tr><th align="left">SKU</th><th align="left">Available</th></tr></thead>
        <tbody>
          {inventory.map(i => (
            <tr key={i.sku}><td>{i.sku}</td><td>{i.quantityAvailable}</td></tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
