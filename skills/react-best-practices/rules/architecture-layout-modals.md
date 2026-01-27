---
title: Layout-Level Modal Management with Imperative Hooks
impact: HIGH
impactDescription: centralized modal state, prevents z-index issues, better UX
tags: architecture, modals, layout, imperative-handle, forward-ref
---

## Layout-Level Modal Management with Imperative Hooks

**Impact: HIGH (centralized modal state, prevents z-index issues, better UX)**

Manage modals at the layout level using `useImperativeHandle` and `forwardRef` to create a centralized modal system. This prevents z-index conflicts, ensures consistent styling, and provides a clean API for opening modals from anywhere in the app.

**Incorrect (component-level modals):**

```tsx
// Multiple modals scattered throughout components
function UserProfile() {
  const [showDeleteModal, setShowDeleteModal] = useState(false)
  const [showEditModal, setShowEditModal] = useState(false)
  
  return (
    <div>
      <button onClick={() => setShowDeleteModal(true)}>Delete</button>
      <button onClick={() => setShowEditModal(true)}>Edit</button>
      
      {/* Z-index conflicts, inconsistent styling */}
      {showDeleteModal && (
        <div className="fixed inset-0 z-50 bg-black/50">
          <DeleteModal onClose={() => setShowDeleteModal(false)} />
        </div>
      )}
      
      {showEditModal && (
        <div className="fixed inset-0 z-50 bg-black/50">
          <EditModal onClose={() => setShowEditModal(false)} />
        </div>
      )}
    </div>
  )
}
```

**Correct (layout-level modal system):**

```tsx
// types/modal.ts
export interface ModalRef {
  openModal: (component: React.ComponentType<any>, props?: any) => void
  closeModal: () => void
  closeAllModals: () => void
}

// components/layout/ModalProvider.tsx
import { forwardRef, useImperativeHandle, useState } from 'react'

interface ModalState {
  id: string
  component: React.ComponentType<any>
  props: any
}

export const ModalProvider = forwardRef<ModalRef>((_, ref) => {
  const [modals, setModals] = useState<ModalState[]>([])

  useImperativeHandle(ref, () => ({
    openModal: (component, props = {}) => {
      const id = Math.random().toString(36).substr(2, 9)
      setModals(prev => [...prev, { id, component, props }])
    },
    
    closeModal: () => {
      setModals(prev => prev.slice(0, -1))
    },
    
    closeAllModals: () => {
      setModals([])
    }
  }))

  return (
    <>
      {modals.map((modal, index) => {
        const Component = modal.component
        return (
          <div
            key={modal.id}
            className="fixed inset-0 bg-black/50 flex items-center justify-center"
            style={{ zIndex: 1000 + index }}
          >
            <Component
              {...modal.props}
              onClose={() => setModals(prev => prev.filter(m => m.id !== modal.id))}
            />
          </div>
        )
      })}
    </>
  )
})

// app/layout.tsx
import { useRef } from 'react'
import { ModalProvider } from '@/components/layout/ModalProvider'

export default function RootLayout({ children }) {
  const modalRef = useRef<ModalRef>(null)

  return (
    <html>
      <body>
        <ModalContext.Provider value={modalRef}>
          {children}
          <ModalProvider ref={modalRef} />
        </ModalContext.Provider>
      </body>
    </html>
  )
}

// hooks/useModal.ts
import { useContext } from 'react'
import { ModalContext } from '@/contexts/ModalContext'

export const useModal = () => {
  const modalRef = useContext(ModalContext)
  
  if (!modalRef?.current) {
    throw new Error('useModal must be used within ModalProvider')
  }
  
  return modalRef.current
}

// Usage in components
function UserProfile() {
  const modal = useModal()
  
  const handleDelete = () => {
    modal.openModal(DeleteUserModal, { userId: user.id })
  }
  
  const handleEdit = () => {
    modal.openModal(EditUserModal, { user })
  }
  
  return (
    <div>
      <button onClick={handleDelete}>Delete</button>
      <button onClick={handleEdit}>Edit</button>
    </div>
  )
}
```

**Advanced pattern with toast integration:**

```tsx
// Enhanced ModalProvider with toast support
export const ModalProvider = forwardRef<ModalRef & ToastRef>((_, ref) => {
  const [modals, setModals] = useState<ModalState[]>([])
  const [toasts, setToasts] = useState<ToastState[]>([])

  useImperativeHandle(ref, () => ({
    // Modal methods
    openModal: (component, props = {}) => {
      const id = Math.random().toString(36).substr(2, 9)
      setModals(prev => [...prev, { id, component, props }])
    },
    
    closeModal: () => setModals(prev => prev.slice(0, -1)),
    closeAllModals: () => setModals([]),
    
    // Toast methods
    showToast: (message, type = 'info') => {
      const id = Math.random().toString(36).substr(2, 9)
      setToasts(prev => [...prev, { id, message, type }])
      
      // Auto-remove after 5 seconds
      setTimeout(() => {
        setToasts(prev => prev.filter(t => t.id !== id))
      }, 5000)
    },
    
    removeToast: (id) => {
      setToasts(prev => prev.filter(t => t.id !== id))
    }
  }))

  return (
    <>
      {/* Modals */}
      {modals.map((modal, index) => (
        <div key={modal.id} className="modal-backdrop" style={{ zIndex: 1000 + index }}>
          <modal.component {...modal.props} onClose={() => closeModal()} />
        </div>
      ))}
      
      {/* Toasts */}
      <div className="fixed top-4 right-4 space-y-2" style={{ zIndex: 2000 }}>
        {toasts.map(toast => (
          <Toast key={toast.id} {...toast} onRemove={() => removeToast(toast.id)} />
        ))}
      </div>
    </>
  )
})
```

This pattern provides:
- **Centralized modal management** - no z-index conflicts
- **Consistent styling** - all modals use same backdrop/positioning
- **Clean API** - `modal.openModal(Component, props)`
- **Type safety** - proper TypeScript interfaces
- **Performance** - modals only render when needed
- **Accessibility** - can add focus management and escape key handling at layout level

Reference: [React useImperativeHandle](https://react.dev/reference/react/useImperativeHandle)