import React, { useState } from 'react';
import { X, PlusCircle, DollarSign, Layers } from 'lucide-react';
import { venueStore } from '../../store/venueStore';
import { Court } from '../../types';

interface AddCourtModalProps {
  isOpen: boolean;
  onClose: () => void;
  venueId?: string;
  onSuccess?: (court: Court) => void;
}

export const AddCourtModal: React.FC<AddCourtModalProps> = ({
  isOpen,
  onClose,
  venueId = 'venue_01',
  onSuccess,
}) => {
  const [name, setName] = useState('');
  const [sport, setSport] = useState<'badminton' | 'pickleball' | string>('badminton');
  const [surfaceType, setSurfaceType] = useState('Thảm Yonex Tiêu Chuẩn');
  const [facilityType, setFacilityType] = useState<'indoor' | 'outdoor'>('indoor');
  const [regularPrice, setRegularPrice] = useState('120000');
  const [peakPrice, setPeakPrice] = useState('180000');
  const [error, setError] = useState('');

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setError('Vui lòng nhập tên sân');
      return;
    }

    const regPriceNum = parseInt(regularPrice, 10) || 120000;
    const peakPriceNum = parseInt(peakPrice, 10) || 180000;

    const created = venueStore.addCourt(venueId, {
      name: name.trim(),
      sport,
      surfaceType,
      facilityType,
      regularPrice: regPriceNum,
      peakPrice: peakPriceNum,
      isActive: true,
    });

    setName('');
    setError('');
    if (onSuccess) {
      onSuccess(created);
    }
    onClose();
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs animate-in fade-in duration-200"
      role="dialog"
      aria-modal="true"
    >
      <div className="relative w-full max-w-lg bg-white dark:bg-[#141B2D] rounded-3xl border border-slate-200 dark:border-slate-800 shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-5 border-b border-slate-100 dark:border-slate-800">
          <div className="flex items-center gap-2.5">
            <div className="w-10 h-10 rounded-2xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <PlusCircle className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-slate-900 dark:text-white">
                Thêm Sân Thể Thao Mới
              </h2>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Thêm sân vào cụm Tao Đàn để lên lịch thi đấu
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-xl text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
            aria-label="Đóng"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {error && (
            <div className="p-3 text-xs text-rose-600 dark:text-rose-400 bg-rose-50 dark:bg-rose-950/40 rounded-xl border border-rose-200 dark:border-rose-900">
              {error}
            </div>
          )}

          {/* Court Name */}
          <div>
            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
              Tên Sân Thể Thao *
            </label>
            <input
              type="text"
              data-testid="input-court-name"
              value={name}
              onChange={(e) => {
                setName(e.target.value);
                if (error) setError('');
              }}
              placeholder="VD: Sân Cầu Lông VIP 05 hoặc Sân Pickleball 09"
              className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900 text-sm text-slate-900 dark:text-white placeholder:text-slate-400 focus:outline-hidden focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-500 transition-all"
            />
          </div>

          {/* Sport and Facility Type */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
                Môn Thể Thao
              </label>
              <select
                data-testid="select-court-sport"
                value={sport}
                onChange={(e) => {
                  const sp = e.target.value;
                  setSport(sp);
                  if (sp === 'badminton') setSurfaceType('Thảm PVC Yonex');
                  else if (sp === 'pickleball') setSurfaceType('Sơn Acrylic US Open');
                  else setSurfaceType('Thảm Silicon');
                }}
                className="w-full px-3 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900 text-sm text-slate-900 dark:text-white focus:outline-hidden focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-500 transition-all"
              >
                <option value="badminton">Cầu lông (Badminton)</option>
                <option value="pickleball">Pickleball</option>
                <option value="football">Bóng đá mini</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
                Khu Vực
              </label>
              <select
                value={facilityType}
                onChange={(e) => setFacilityType(e.target.value as 'indoor' | 'outdoor')}
                className="w-full px-3 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900 text-sm text-slate-900 dark:text-white focus:outline-hidden focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-500 transition-all"
              >
                <option value="indoor">Trong nhà (Indoor)</option>
                <option value="outdoor">Ngoài trời (Outdoor)</option>
              </select>
            </div>
          </div>

          {/* Surface Type */}
          <div>
            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
              Loại Mặt Sân
            </label>
            <div className="relative">
              <input
                type="text"
                data-testid="input-surface-type"
                value={surfaceType}
                onChange={(e) => setSurfaceType(e.target.value)}
                placeholder="VD: Thảm PVC Yonex, Thảm Silicon..."
                className="w-full pl-9 pr-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900 text-sm text-slate-900 dark:text-white focus:outline-hidden focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-500 transition-all"
              />
              <Layers className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
            </div>
          </div>

          {/* Pricing Row */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
                Giá Khung Giờ Thường (đ/h)
              </label>
              <div className="relative">
                <input
                  type="number"
                  data-testid="input-regular-price"
                  value={regularPrice}
                  onChange={(e) => setRegularPrice(e.target.value)}
                  step="10000"
                  min="0"
                  className="w-full pl-8 pr-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900 text-sm text-slate-900 dark:text-white focus:outline-hidden focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-500 transition-all"
                />
                <DollarSign className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-3.5" />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
                Giá Khung Giờ Cao Điểm (đ/h)
              </label>
              <div className="relative">
                <input
                  type="number"
                  data-testid="input-peak-price"
                  value={peakPrice}
                  onChange={(e) => setPeakPrice(e.target.value)}
                  step="10000"
                  min="0"
                  className="w-full pl-8 pr-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900 text-sm text-slate-900 dark:text-white focus:outline-hidden focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-500 transition-all"
                />
                <DollarSign className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-3.5" />
              </div>
            </div>
          </div>

          {/* Action buttons */}
          <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100 dark:border-slate-800">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2.5 rounded-xl text-xs font-semibold text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
            >
              Hủy
            </button>
            <button
              type="submit"
              data-testid="btn-submit-court"
              className="px-5 py-2.5 rounded-xl text-xs font-bold bg-emerald-500 hover:bg-emerald-600 text-white shadow-xs shadow-emerald-500/20 transition-all flex items-center gap-1.5"
            >
              <PlusCircle className="w-4 h-4" />
              <span>Thêm Sân Thể Thao</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default AddCourtModal;
