import { useCart } from '../context/CartContext';
import { useTheme } from '../context/ThemeContext';
import { useAuth } from '../context/AuthContext';
import { Link, useNavigate } from 'react-router-dom';

export default function Cart() {
  const { items, removeFromCart, updateQuantity, getTotalPrice, clearCart } = useCart();
  const { darkMode } = useTheme();
  const { isLoggedIn } = useAuth();
  const navigate = useNavigate();

  // Redirect to login if not authenticated
  if (!isLoggedIn) {
    navigate('/login?error=Please login to view your cart');
    return null;
  }

  const totalPrice = getTotalPrice();

  if (items.length === 0) {
    return (
      <div className={`min-h-screen ${darkMode ? 'bg-dark' : 'bg-gray-100'} pt-20 px-4 transition-colors duration-300`}>
        <div className="max-w-7xl mx-auto py-8">
          <h1 className={`text-3xl font-bold ${darkMode ? 'text-light' : 'text-gray-800'} mb-6 transition-colors duration-300`}>
            Shopping Cart
          </h1>
          <div className={`${darkMode ? 'bg-gray-800' : 'bg-white'} rounded-lg shadow-lg p-8 text-center transition-colors duration-300`}>
            <svg 
              className={`mx-auto h-24 w-24 ${darkMode ? 'text-gray-600' : 'text-gray-400'} mb-4`}
              fill="none" 
              viewBox="0 0 24 24" 
              stroke="currentColor"
            >
              <path 
                strokeLinecap="round" 
                strokeLinejoin="round" 
                strokeWidth={1.5} 
                d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" 
              />
            </svg>
            <h2 className={`text-2xl font-semibold ${darkMode ? 'text-light' : 'text-gray-800'} mb-4 transition-colors duration-300`}>
              Your cart is empty
            </h2>
            <p className={`${darkMode ? 'text-gray-400' : 'text-gray-600'} mb-6 transition-colors duration-300`}>
              Add some products to get started!
            </p>
            <Link 
              to="/products" 
              className="inline-block bg-primary hover:bg-accent text-white px-6 py-3 rounded-lg transition-colors"
            >
              Browse Products
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className={`min-h-screen ${darkMode ? 'bg-dark' : 'bg-gray-100'} pt-20 px-4 transition-colors duration-300`}>
      <div className="max-w-7xl mx-auto py-8">
        <div className="flex justify-between items-center mb-6">
          <h1 className={`text-3xl font-bold ${darkMode ? 'text-light' : 'text-gray-800'} transition-colors duration-300`}>
            Shopping Cart
          </h1>
          <button
            onClick={clearCart}
            className={`${darkMode ? 'text-red-400 hover:text-red-300' : 'text-red-600 hover:text-red-700'} transition-colors`}
          >
            Clear Cart
          </button>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Cart Items */}
          <div className="lg:col-span-2 space-y-4">
            {items.map(item => {
              const itemPrice = item.discount ? item.price * (1 - item.discount) : item.price;
              const itemTotal = itemPrice * item.quantity;

              return (
                <div 
                  key={item.productId} 
                  className={`${darkMode ? 'bg-gray-800' : 'bg-white'} rounded-lg shadow-lg p-4 transition-colors duration-300`}
                >
                  <div className="flex items-center space-x-4">
                    <div className={`w-24 h-24 ${darkMode ? 'bg-gray-700' : 'bg-gray-100'} rounded-lg flex-shrink-0 transition-colors duration-300`}>
                      <img 
                        src={`/${item.imgName}`} 
                        alt={item.name}
                        className="w-full h-full object-contain p-2"
                      />
                    </div>
                    
                    <div className="flex-grow">
                      <h3 className={`text-lg font-semibold ${darkMode ? 'text-light' : 'text-gray-800'} transition-colors duration-300`}>
                        {item.name}
                      </h3>
                      <div className="mt-2">
                        {item.discount ? (
                          <div>
                            <span className="text-gray-500 line-through text-sm mr-2">
                              ${item.price.toFixed(2)}
                            </span>
                            <span className="text-primary font-bold">
                              ${itemPrice.toFixed(2)}
                            </span>
                          </div>
                        ) : (
                          <span className="text-primary font-bold">
                            ${item.price.toFixed(2)}
                          </span>
                        )}
                      </div>
                    </div>

                    <div className="flex items-center space-x-4">
                      <div className={`flex items-center space-x-3 ${darkMode ? 'bg-gray-700' : 'bg-gray-200'} rounded-lg p-1 transition-colors duration-300`}>
                        <button 
                          onClick={() => updateQuantity(item.productId, item.quantity - 1)}
                          className={`w-8 h-8 flex items-center justify-center ${darkMode ? 'text-light' : 'text-gray-700'} hover:text-primary transition-colors duration-300`}
                          aria-label={`Decrease quantity of ${item.name}`}
                        >
                          <span aria-hidden="true">-</span>
                        </button>
                        <span className={`${darkMode ? 'text-light' : 'text-gray-800'} min-w-[2rem] text-center transition-colors duration-300`}>
                          {item.quantity}
                        </span>
                        <button 
                          onClick={() => updateQuantity(item.productId, item.quantity + 1)}
                          className={`w-8 h-8 flex items-center justify-center ${darkMode ? 'text-light' : 'text-gray-700'} hover:text-primary transition-colors duration-300`}
                          aria-label={`Increase quantity of ${item.name}`}
                        >
                          <span aria-hidden="true">+</span>
                        </button>
                      </div>

                      <div className="w-24 text-right">
                        <span className={`text-lg font-bold ${darkMode ? 'text-light' : 'text-gray-800'} transition-colors duration-300`}>
                          ${itemTotal.toFixed(2)}
                        </span>
                      </div>

                      <button
                        onClick={() => removeFromCart(item.productId)}
                        className={`${darkMode ? 'text-red-400 hover:text-red-300' : 'text-red-600 hover:text-red-700'} transition-colors`}
                        aria-label={`Remove ${item.name} from cart`}
                      >
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Order Summary */}
          <div className="lg:col-span-1">
            <div className={`${darkMode ? 'bg-gray-800' : 'bg-white'} rounded-lg shadow-lg p-6 sticky top-24 transition-colors duration-300`}>
              <h2 className={`text-2xl font-bold ${darkMode ? 'text-light' : 'text-gray-800'} mb-4 transition-colors duration-300`}>
                Order Summary
              </h2>
              
              <div className="space-y-3 mb-6">
                <div className={`flex justify-between ${darkMode ? 'text-gray-300' : 'text-gray-600'} transition-colors duration-300`}>
                  <span>Items ({items.length})</span>
                  <span>${totalPrice.toFixed(2)}</span>
                </div>
                <div className={`flex justify-between ${darkMode ? 'text-gray-300' : 'text-gray-600'} transition-colors duration-300`}>
                  <span>Shipping</span>
                  <span>Calculated at checkout</span>
                </div>
                <div className="border-t border-gray-600 pt-3">
                  <div className={`flex justify-between text-xl font-bold ${darkMode ? 'text-light' : 'text-gray-800'} transition-colors duration-300`}>
                    <span>Total</span>
                    <span className="text-primary">${totalPrice.toFixed(2)}</span>
                  </div>
                </div>
              </div>

              <button 
                className="w-full bg-primary hover:bg-accent text-white py-3 px-4 rounded-lg font-semibold transition-colors"
              >
                Proceed to Checkout
              </button>

              <Link 
                to="/products" 
                className={`block text-center ${darkMode ? 'text-primary' : 'text-primary'} hover:underline mt-4 transition-colors`}
              >
                Continue Shopping
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
